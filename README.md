# BF Tool
A Brainf**k tool written in C3.

## Planned Features
 - [x] Evaluate a Brainf**k file
 - [ ] Brainf**k REPL
 - [ ] Brainf**k -> C compiler
 - [ ] Optimalizations of the code
   - [ ] Combine subsequent `+`, `-`, `<`, `>` into one
   - [ ] Eliminate dead loops
   - [ ] Convert common patterns (like `[-]`)
   - [ ] Convert static loops into combined values

## Usage
Currently it can only read, parse & evaluate a Brainf**k file.
```
$ c3c run -- eval <FILE>
```
Or build and execute binary yourself.
```
$ c3c build
$ ./build/bftool eval <FILE>
```
