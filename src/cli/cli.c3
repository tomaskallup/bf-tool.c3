module bftool::cli;
import std::io;
import std::os::argparse;

import bftool::config;

fn int! command_handler(ArgParse* args, Config config){
	if(args.arguments.len == 0){
		args.print_usage()!!;
		return 1;
	}

	switch(args.arguments[0]) {
		case "eval":
      return eval::run_eval(args, config);
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
  Config config;
  ArgParse agp = {
    .description = "Brainf**k tool written in C3",
    .usage = "<subcommand> [cmd-args]",
    .epilog = EPILOG,
    .options = { 
      argparse::help_opt(),
      {.long_name = "opt-batch-ops", .value = &config.optimisation.batch_ops, .help = "Enable batch-ops optimisation"},
    }, 
    .flags = {
      .stop_at_non_option = true,
    },
  };

	if(catch err = agp.parse(args)){
		agp.print_usage()!!;
		return 1;
	}

  int result = command_handler(&agp, config)!;

  return result;
}
