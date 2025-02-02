module c3_bftool::cli;
import std::io;
import std::os::argparse;

fn int! command_handler(ArgParse* args){
	if(args.arguments.len == 0){
		args.print_usage()!!;
		return 1;
	}

	switch(args.arguments[0]) {
		case "eval":
      return eval::run_eval(args);
    default:
			io::printfn("Unknown command");
			args.print_usage()!!;
			return 1;
	}
}

const String EPILOG = `Subcommands:
 - eval

To get more information about a subcommand run <subcommand> --help
`;

fn int! run(String[] args) {
  ArgParse agp = {
    .description = "Brainf**k tool written in C3",
    .usage = "<subcommand> [cmd-args]",
    .epilog = EPILOG,
    .options = { 
      argparse::help_opt(),
    }, 
    .flags = {
      .stop_at_non_option = true,
    },
  };

	if(catch err = agp.parse(args)){
		agp.print_usage()!!;
		return 1;
	}

  int result = command_handler(&agp)!;

  return result;
}
