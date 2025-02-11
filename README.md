# BF Tool
A Brainf**k tool written in C3.

## Planned Features
 - [x] Evaluate a Brainf**k file
 - [ ] Brainf**k REPL
 - [x] Brainf**k -> C compiler
 - [ ] Optimisations of the code
   - [x] Combine subsequent `+`, `-`, `<`, `>` into one
   - [ ] Eliminate dead loops
   - [ ] Convert common patterns (like `[-]`)
   - [ ] Convert static loops into combined values

## Usage
### Optimisations
Optimisation options are passed before the subcommand, so `./build/bftool -O1 eval <FILE>` etc.
All of them are described in [OPTIMISATION.md](./OPTIMISATION.md) along with implementation status/notes.

### Eval
To read, parse & evaluate a Brainf**k file:
```
$ c3c run -- eval <FILE>
```
Or build and execute binary yourself.
```
$ c3c build
$ ./build/bftool eval <FILE>
```

### Compile to C
To read, parse & compile a Brainf**k file to C (outputs to stdout):
```
$ c3c run -- compile <FILE>
```
Or build and execute binary yourself.
```
$ c3c build
$ ./build/bftool compile <FILE>
```
If you want to write the result to a file:
```
$ c3c run -- compile -o my_file.c <FILE>
```
