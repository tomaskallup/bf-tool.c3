module bftool::config;

struct Config {
  struct optimisation {
    ushort level;
    bool batch_ops;
    bool zero_loop;
    bool remove_dead;
    bool reduce_loops;
  }
}
