module std::collections::list(<Type>);
import std::io;
<*
 @require index + len <= self.size `Removed range out of bounds`
 @require len > 0 `Range should span atleast one element`
*>
fn void List.remove_range(&self, usz index, usz len)
{
	usz old_size = self.size;
	self.set_size(self.size - len);
  if (index + len == old_size) return;
	self.entries[index .. self.size - len + 1] = self.entries[index + len .. old_size - 1];
}

module bftool::program(<MEM_SIZE>);

import bftool::lexer;
import bftool::config;
import std::collections::list;
import std::io;
import std::math;
import libc;

enum Opcode {
  PRINT,
  READ,

  MOVP,

  CHD,
  SETD,

  // Conditional jump when non-empty (> 0)
  JMP,
  // Conditional jump when empty when empty (== 0)
  JMPE,
}

struct Operation (Printable) {
  Opcode opcode;
  long value;
}

fn String Operation.to_string(&self, Allocator allocator) @dynamic
{
  return string::format("%s: %d", self.opcode, self.value, allocator: allocator);
}

struct Program {
  char[MEM_SIZE] data;
  Token[] tokens;
  List(<Operation>) ops;
  usz index;
  usz pos;
  Config config;
}

fault ProgramValidationFault {
  UNCLOSED_LOOP,
  UNOPENED_LOOP,
}

fault ProgramExecutionFault {
  MEMORY_OVERFLOW,
  MEMORY_UNDERFLOW,
}

fn void! Program.parse(&self) {
  if (!self.ops.allocator) self.ops.new_init();
  self.ops.clear();
  foreach OUTER: (token: self.tokens) {
    Operation op;
    switch (token.type) {
      case PRINT:
      op.opcode = PRINT;
      case READ:
      op.opcode = READ;
      case INCP:
      op.opcode = MOVP;
      op.value = 1;
      case DECP:
      op.opcode = MOVP;
      op.value = -1;
      case INC:
      op.opcode = CHD;
      op.value = 1;
      case DEC:
      op.opcode = CHD;
      op.value = -1;
      case LOOPS:
      // Will need backpatching, when LOOPE is found
      op.opcode = JMPE;
      case LOOPE:
      op.opcode = JMP;
      long index;
      bool found;
      foreach_r (long i, search_op: self.ops) {
        if (search_op.opcode == JMPE && !search_op.value) {
          index = i;
          found = true;
          break;
        }
      }
      if (!found) return ProgramValidationFault.UNOPENED_LOOP?;
      self.ops[index].value = self.ops.len() + 1;
      op.value = index + 1;
      case ERROR:
      nextcase;
      case EOF:
      break OUTER;
      default:
      unreachable("Invalid token found %s", token.type);
    }

    if (self.config.optimisation.batch_ops) {
      if (self.ops.len() > 0) {
        Operation* prev_op = self.ops.get_ref(self.ops.len() - 1);
        if (prev_op.opcode == op.opcode) {
          switch {
            case op.opcode == MOVP: nextcase;
            case op.opcode == CHD:
              prev_op.value += op.value;
              if (!prev_op.value) self.ops.remove_at(self.ops.len() - 1);
              continue;
          }
        }
      }
    }

    self.ops.push(op);
  }

  bool can_jump_to_zero;
  foreach (index, op: self.ops) {
    if (op.opcode == JMPE && !op.value) return ProgramValidationFault.UNCLOSED_LOOP?;
    if (index == 0 && op.opcode == JMPE) can_jump_to_zero = true;
    if (op.opcode == JMP && !op.value && !can_jump_to_zero) return ProgramValidationFault.UNOPENED_LOOP?;
  }
}

fn void Program.optimise(&self) {
  @pool() {
    if (self.config.optimisation.zero_loop) {
      List(<usz>) zero_loops;
      zero_loops.temp_init();
      usz zero_loop_index = 0;
      foreach (index, op: self.ops) {
        switch (zero_loop_index) {
          case 0:
          if (op.opcode == JMPE) zero_loop_index++;
          case 1:
          if (op.opcode == CHD && op.value == -1) { zero_loop_index++; }
            else { zero_loop_index = 0; }
          case 2:
          if (op.opcode == JMP && op.value == index - 1) zero_loops.push(index - 2);
          zero_loop_index = 0;
        }
      }

      if (zero_loops.len()) {
        foreach_r (loop_index: zero_loops) {
          self.ops.remove_range(loop_index + 1, 2);
          self.ops[loop_index] = {.opcode = SETD, .value = 0};

          // Fix jumps
          foreach (&op: self.ops) {
            if ((op.opcode == JMPE || op.opcode == JMP) && op.value > loop_index) op.value -= 2;
          }
        }
      }
    }
  };
}

fn usz! Program.move_index(&self, long dir) {
  long new_index = self.index + dir;

  if (new_index >= MEM_SIZE) return ProgramExecutionFault.MEMORY_OVERFLOW?;

  if (new_index < 0) return ProgramExecutionFault.MEMORY_UNDERFLOW?;

  self.index = new_index;

  return self.index;
}

fn void Program.print(self) {
  io::printn("Program start");
  foreach (index, op: self.ops) {
    io::printfn("%d, %s", index, op);
  }
  io::printn("Program end");
}

fn void! Program.evaluate(&self) {
  self.parse()!;
  self.optimise();

  self.print();

  while (self.pos < self.ops.len()) {
    Operation op = self.ops[self.pos++];
    switch (op.opcode) {
      case JMPE:
      if (!self.data[self.index]) {
        self.pos = op.value;
      }
      case JMP:
      if (self.data[self.index]) {
        self.pos = op.value;
      }
      case PRINT:
      if (self.data[self.index]) {
        io::printf("%c", self.data[self.index]);
        io::stdout().flush()!;
      }
      case READ:
      char in = io::stdin().read_byte() ?? 0;
      self.data[self.index] = in;
      case MOVP:
      self.move_index(op.value)!;
      case CHD:
      self.data[self.index]+=(char)op.value;
      case SETD:
      self.data[self.index]=(char)op.value;
    }
  }
}
