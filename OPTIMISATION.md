# Optimisation
There are different types of optimisation implemented, these can be toggled as individual features or in groups via `-O` flag.

## Levels

### -O1
Alias for `--batch-ops --zero-loop`.

## Features

### --batch-ops (partial)
Simplest optimisation, which simply converts subsequent operations into one.
So `+++` => `{.opcode = CHD, .value = 3}` etc.
So `<<<` => `{.opcode = MOVP, .value = -3}` etc.

It will also remove redundant ops so `<>`, `+-+-` and so on would get optimised out. (unimplemented)

### --zero-loop (unimplemented)
Convert zeroing loops into single op.
So `[-]` => `{.opcode = CHD, .value = 0}`

### --remove-dead (unimplemented)
Removes dead code, like comment loops.
So `[-][......++++]` would get reduced to just `[-]`, if the cell is used later on, removed completely if the cell is never accessed.

### --reduce-loops (unimplemented)
Static loops (those not affected by user input via `,`) are converted into batch operations
So `+++[>++<-]` => `[{.opcode = MOVP, .value = 1}{.opcode = CHD, .value = 6}]` etc.
