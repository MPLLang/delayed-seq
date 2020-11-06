# delayed-seq
Experiments with parallel delayed sequences in ML and CPP

## Setup

Fist, install [`mpl-switch`](https://github.com/MPLLang/mpl-switch). Then,
run the following to install versions of `mpl` needed for experiments. This
will take a long time.
```
$ scripts/init
```

## Run it

The files [`ml-exp.json`](./ml-exp.json) and [`cpp-exp.json`](./cpp-exp.json)
define benchmark parameters.
Do the following to run both:
```
$ ./run
```
This creates a directory `results/` named with the current time. Each line
of a results file is a JSON object with various info about the run.

To see a summary of results, do:
```
$ ./report
```

## Notes

* In `cpp/` and `ml/`, there needs to be a `Makefile` that has targets
of the form `BENCH.CONFIG.bin`.

* The `ml-exp.json` and `cpp-exp.json` files are passed to the `scripts/gencmds`
utility. Ask Sam about documentation. Basically, `gencmds` produces a bunch
of "rows" where each row has key/value pairs that define one shell command.
These rows are then passed to `scripts/runcmds`, which runs each command
and writes out the results. Important key/value pairs in the rows include:
  - `cmd`: the shell command to run the experiment
  - `cwd`: the subdirectory in which to run this command
  - `tag`: a unique name for this experiment
  - `procs`: how many processors to run on
  - `bench`: the name of the benchmark
  - `config`: the configuration used to compile the benchmark
