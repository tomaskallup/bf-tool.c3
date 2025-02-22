module bftool::compiler(<MEM_SIZE>);

import std::io;
import std::math;
import bftool::program;

fn void! compile_to_c(Program(<MEM_SIZE>) program, File* out_file) {
  if (!program.ops.allocator) {
    program.parse()!;
    program.optimise();
  }

  io::fprintn(out_file, "#include <stdio.h>\n")!;
  io::fprintfn(out_file, "unsigned char data[%d] = {0};", MEM_SIZE)!;
  io::fprintn(out_file, "unsigned long idx = 0;")!;

  io::fprintn(out_file, "int main() {")!;

  @pool() {
    String indent = "  ";

    foreach (op: program.ops) {
      switch (op.opcode) {
        case JMPE:
          io::fprintfn(out_file, "%swhile (data[idx]) {", indent)!;
          indent = indent.tconcat("  ");
        case JMP:
          indent = indent[:indent.len-2];
          io::fprintfn(out_file, "%s}", indent)!;
        case PRINT:
          io::fprintfn(out_file, "%sif (data[idx]) printf(\"%%c\", data[idx]);", indent)!;
        case READ:
          io::fprintfn(out_file, "%sdata[idx] = getchar();", indent)!;
        case MOVP:
          io::fprintfn(out_file, "%sidx%c=%d;", indent, op.value < 0 ? '-' : '+', math::abs(op.value))!;
        case CHD:
          io::fprintfn(out_file, "%sdata[idx]%c=%d;", indent, op.value < 0 ? '-' : '+', math::abs(op.value))!;
        case SETD:
          io::fprintfn(out_file, "%sdata[idx]=%d;", indent, op.value)!;
      }
    }
    io::fprintn(out_file, "  return 0;")!;
    io::fprintn(out_file, "}")!;
  };
}
