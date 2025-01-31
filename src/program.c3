module c3_bftool::program(<MEM_SIZE>);

import c3_bftool::lexer;
import std::collections::list;
import std::io;

struct Program {
  char[MEM_SIZE] data;
  Token[] ops;
}

fault ProgramValidationFault {
  UNCLOSED_LOOP,
  UNOPENED_LOOP,
}

// @TODO: This should be a `parse` method, which would parse the code into ops with values (to make jumps easier)
// and could later be optimized
fn void! Program.validate(self) {
  @pool() {
    List(<usz>) stack;
    stack.temp_init();
    foreach (index, op: self.ops) {
      switch (op.type) {
        case LOOPS:
          stack.push(index);
        case LOOPE:
          if (stack.len() == 0) return ProgramValidationFault.UNOPENED_LOOP?;
          stack.pop()!;
        default:
          // All other operations are just considered valid.
      }
    }

    if (stack.len() > 0) return ProgramValidationFault.UNCLOSED_LOOP?;
  };
}

fn usz move_index(usz pos, int dir) {
  // Handle underflow
  if (dir < 0 && (pos == 0 || (pos + dir) > pos)) return 0;
  // Handle overflow
  if (dir > 0 && (pos == MEM_SIZE - 1 || (MEM_SIZE - pos) <= dir)) return MEM_SIZE - 1;

  return pos + dir;
}

fn void! Program.evaulate(&self) {
  self.validate()!;

  usz index, pos;

  // @TODO: This should run through an optimizer, at least reducing multiple operations of the same type to a single operation
  @pool() {
    List(<usz>) stack;
    stack.temp_init();
    bool skipping = false;
    while (pos < self.ops.len) {
      Token op = self.ops[pos++];

      if (skipping) {
        if (op.type == LOOPE) skipping = false;
        continue;
      }
      switch (op.type) {
        case LOOPS:
          if (self.data[index]) {
            stack.push(pos - 1);
          } else {
            skipping = true;
          }
        case LOOPE:
          usz new_pos = stack.pop()!;
          if (self.data[index]) {
            pos = new_pos;
          }
        case PRINT:
          if (self.data[index]) {
            io::printf("%c", self.data[index]);
          }
        case READ:
        case INCP:
          index = move_index(index, 1);
        case DECP:
          index = move_index(index, -1);
        case INC:
          self.data[index]++;
        case DEC:
          self.data[index]--;
        case EOF:
        default:
      }
    }
  };
  io::printn();
}
