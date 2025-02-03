module c3_bftool::cli::eval;

import std::io;
import std::os::argparse;
import c3_bftool::lexer;
import c3_bftool::program;

const MEM_SIZE = 100;

fn int run_eval(ArgParse* args) {
  ArgParse agp = {
    .program_name = args.program_name,
    .description = "Evaluate a Brainf**k file",
    .usage = "eval <file>",
    .options = { 
      argparse::help_opt(),
    }, 
  };

	if(catch err = agp.parse(args.arguments)){
		agp.print_usage()!!;
		return 1;
	}
  
	if(agp.arguments.len == 0){
    io::printn("You must provide a path to the file to evaluate.");
		agp.print_usage()!!;
		return 1;
	}

  String path = agp.arguments[0];
  char[]! data = file::load_temp(path);

  if (catch error = data) {
    io::eprintfn("Failed to load file %s: %s", path, error);

    return 1;
  }

  Lexer lexer = { .data = data };

  Token[] tokens = lexer.lex();

  io::printn("Parsed program:");
  io::printn(tokens);

  Program(<MEM_SIZE>) program = {
    .tokens = tokens,
  };

  io::printn("Output:");
  program.evaluate()!!;
  io::printn();

  return 0;
}
