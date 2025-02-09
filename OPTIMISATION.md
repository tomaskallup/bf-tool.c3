# Optimisation
There are different types of optimisation implemented, these can be toggled as individual features or in groups via `-O` flag.

## Levels

### -O1
Alias for `--batch-ops --zero-loop`.

## Features

### --batch-ops
Simplest optimisation, which simply converts subsequent operations into one.
So `+++` => `{.opcode = CHD, .value = 3}` etc.
So `<<<` => `{.opcode = MOVP, .value = -3}` etc.
However `+++---` will result in `[{.opcode = CHD, .value = 3},{.opcode = CHD, .value = -3}]`, since there is no under/overflow, if the call has value of `255`, after these operations it will result in `252`, so these cells cannot be optimised out by this simple check.

### --zero-loop (unimplemented)
Convert zeroing loops into single op.
So `[-]` => `{.opcode = SETD, .value = 0}`

### --remove-dead (unimplemented)
Removes dead code, like comment loops.
So `[-][......++++]` would get reduced to just `[-]`, if the cell is used later on, removed completely if the cell is never accessed.

### --reduce-loops (unimplemented)
Static loops (those not affected by user input via `,`) are converted into batch operations
So `+++[>++<-]` => `[{.opcode = MOVP, .value = 1}{.opcode = CHD, .value = 6}]` etc.
