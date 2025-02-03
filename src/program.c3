module c3_bftool::program(<MEM_SIZE>);

import c3_bftool::lexer;
import std::collections::list;
import std::io;
import libc;

enum Opcode {
  PRINT,
  READ,

  MOVP,

  CHD,

  // Conditional jump when non-empty (> 0)
  JMP,
  // Conditional jump when empty when empty (== 0)
  JMPE,
}

struct Operation {
  Opcode opcode;
  long* value;
}

struct Program {
  char[MEM_SIZE] data;
  Token[] tokens;
  List(<Operation>) ops;
}

fault ProgramValidationFault {
  UNCLOSED_LOOP,
  UNOPENED_LOOP,
}

const long ONE = 1;
const long MINUS_ONE = -1;

fn void! Program.parse(&self) {
  if (!self.ops.allocator) self.ops.new_init();
  foreach (op: self.ops) {
    if (op.opcode == JMP || op.opcode == JMPE) free(op.value);
  }
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
      op.value = &ONE;
      case DECP:
      op.opcode = MOVP;
      op.value = &MINUS_ONE;
      case INC:
      op.opcode = CHD;
      op.value = &ONE;
      case DEC:
      op.opcode = CHD;
      op.value = &MINUS_ONE;
      case LOOPS:
      // Will need backpatching, when LOOPE is found
      op.opcode = JMPE;
      case LOOPE:
      op.opcode = JMP;
      long index;
      bool found;
      foreach_r (long i, search_op: self.ops) {
        if (search_op.opcode == JMPE && search_op.value == null) {
          index = i;
          found = true;
        }
      }
      if (!found) return ProgramValidationFault.UNOPENED_LOOP?;
      self.ops[index].value = mem::new(long, self.ops.len());
      op.value = mem::new(long, index);
      case ERROR:
      nextcase;
      case EOF:
      break OUTER;
      default:
      unreachable("Invalid token found %s", token.type);
    }
    self.ops.push(op);
  }

  foreach (op: self.ops) {
    if (op.opcode == JMP && op.value == null) return ProgramValidationFault.UNCLOSED_LOOP?;
  }
}

fn usz move_index(usz pos, long dir) {
  // Handle underflow
  if (dir < 0 && (pos == 0 || (pos + dir) > pos)) return 0;
  // Handle overflow
  if (dir > 0 && (pos == MEM_SIZE - 1 || (MEM_SIZE - pos) <= dir)) return MEM_SIZE - 1;

  return pos + dir;
}

fn void! Program.evaluate(&self) {
  self.parse()!;

  usz index, pos;

  while (pos < self.ops.len()) {
    Operation op = self.ops[pos++];
    switch (op.opcode) {
      case JMPE:
      if (!self.data[index]) {
        pos = *op.value;
      }
      case JMP:
      if (self.data[index]) {
        pos = *op.value;
      }
      case PRINT:
      if (self.data[index]) {
        io::printf("%c", self.data[index]);
      }
      case READ:
      char! in = io::stdin().read_byte();
      if (catch in) continue;
      self.data[index] = in;
      case MOVP:
      index = move_index(index, *op.value);
      case CHD:
      self.data[index]+=(char)*op.value;
    }
  }
}
