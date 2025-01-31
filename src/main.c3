module c3_bftool;

import std::io;
import c3_bftool::lexer;
import c3_bftool::program;

const MEM_SIZE = 100;

fn int main(String[] args)
{
  if (args.len != 2) {
    io::eprintfn("Usage: %s <file>", args[0]);
    return 1;
  }

  char[]! data = file::load_temp(args[1]);

  if (catch error = data) {
    io::eprintfn("Faile to load file %s: %s", args[1], error);

    return 1;
  }

  Lexer lexer = { .data = data };

  Token[] tokens = lexer.lex();

  io::printn(tokens);

  Program(<MEM_SIZE>) program = {
    .ops = tokens,
  };

  program.evaulate()!!;

  return 0;
}
