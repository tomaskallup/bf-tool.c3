module bftool::cli::compile;

import std::io;
import std::os::argparse;
import bftool::lexer;
import bftool::program;
import bftool::config;
import bftool::compiler;

const MEM_SIZE = 100;

fn int run_compile(ArgParse* args, Config config) {
  String out_file_path;
  ArgParse agp = {
    .program_name = args.program_name,
    .description = "Compile a Brainf**k file",
    .usage = "compile <file>",
    .options = { 
      argparse::help_opt(),
      { .short_name = 'o', .long_name = "out", .value = &out_file_path},
    }, 
  };

	if (catch err = agp.parse(args.arguments)){
		agp.print_usage()!!;
		return 1;
	}
  
	if (agp.arguments.len == 0){
    io::printn("You must provide a path to the file to compile.");
		agp.print_usage()!!;
		return 1;
	}

  String path = agp.arguments[0];
  char[]! data = file::load_temp(path);

  if (catch error = data) {
    io::eprintfn("Failed to load file %s: %s", path, error);

    return 1;
  }

  File! out_file = out_file_path.len ? file::open(out_file_path, "wb") : *io::stdout();

  if (catch error = out_file) {
    io::eprintfn("Failed to open file for write %s: %s", out_file_path, error);

    return 1;
  }

  Lexer lexer = { .data = data };

  Token[] tokens = lexer.lex();

  Program(<MEM_SIZE>) program = {
    .tokens = tokens,
    .config = config,
  };

  if (catch error = compiler::compile_to_c(<MEM_SIZE>)(program, &out_file)) {
    io::eprintfn("Compilation failed %s: %s", path, error);

    return 1;
  }

  return 0;
}
