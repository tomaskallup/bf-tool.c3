# Optimisation
There are different types of optimisation implemented, these can be toggled as individual features or in groups via `-O` flag.

## Levels

### -O1
Alias for `--batch-ops --zero-loop`.

## Features

### --batch-ops
Simplest optimisation, which simply converts subsequent operations into one.
 - `+++` => `{.opcode = CHD, .value = 3}` etc.
 - `<<<` => `{.opcode = MOVP, .value = -3}` etc.

### --zero-loop
Convert zeroing loops into single op.
 - `[-]` => `{.opcode = SETD, .value = 0}`

### --remove-dead (unimplemented)
Removes dead code, like comment loops.
 - `[-][......++++]` would get reduced to just `[-]`, if the cell is used later on, removed completely if the cell is never accessed.
 - `++[-]>+[>+++<-].` would get reduced to `>+[>+++<-].`
 - `[-]++[-]++.` would get reduced to `++.`
 - `+++>[-]<--` would get reduced to `+`


### --reduce-loops (unimplemented)
Static loops (those not affected by user input via `,` and output `.`) are converted into batch operations
 - `+++[>++<-]` => `[{.opcode = CHD, .value = 3},{.opcode = MOVP, .value = 1}{.opcode = CHD, .value = 6},{.opcode = MOVP, .value = -1}{.opcode = CHD, .value = -3}]`
