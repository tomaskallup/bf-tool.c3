module bftool::program(<MEM_SIZE>);

import bftool::lexer;
import bftool::config;
import std::collections::list;
import std::io;
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
      self.ops[index].value = self.ops.len();
      op.value = index;
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

fn usz Program.move_index(&self, long dir) {
  // Handle underflow
  if (dir < 0 && (self.index == 0 || (self.index + dir) > self.index)) {
    self.index = 0;
  } else if (dir > 0 && (self.index == MEM_SIZE - 1 || (MEM_SIZE - self.index) <= dir)) {
    // Handle overflow
    self.index = MEM_SIZE - 1;
  } else {
    self.index = self.index + dir;
  }

  return self.index;
}

fn void! Program.evaluate(&self) {
  self.parse()!;

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
      }
      case READ:
      char in = io::stdin().read_byte() ?? 0;
      self.data[self.index] = in;
      case MOVP:
      self.move_index(op.value);
      case CHD:
      self.data[self.index]+=(char)op.value;
      case SETD:
      self.data[self.index]=(char)op.value;
    }
  }
}
