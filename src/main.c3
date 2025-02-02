module c3_bftool;

import std::io;
import c3_bftool::cli;

fn int main(String[] args)
{
  if (catch error = cli::run(args)) {
    io::eprintfn("Error %s", error);

    return 1;
  }

  return 0;
}
