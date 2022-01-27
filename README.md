# delayed-seq
This repo contains all code necessary for reproducing the experiments in the
following paper:

> Parallel Block-Delayed Sequences.
> Sam Westrick, Mike Rainey, Daniel Anderson, and Guy E. Blelloch.
> PPoPP 2022

It includes code for both
[MPL](https://github.com/MPLLang/mpl) and C++, including both the
delayed-sequences library and all benchmarks.

An artifact was published with the paper, and is available on
[Zenodo](https://zenodo.org/record/5733288). The version of this repo used
to generate the artifact is preserved on the
[ppopp22-artifact](https://github.com/mpllang/delayed-seq/tree/ppopp22-artifact)
branch. **If you are interested in reproducing experimental results from the
paper, we recommending using the artifact directly.**

The [main](https://github.com/mpllang/delayed-seq/tree/main) branch includes
improvements made to the libraries and benchmarks after the artifact was
published. These changes include:
  * For MPL, a cleaned-up library implementation which is easier to understand
  and maintain. The new library code is available at
  [`ml/lib/NewDelayedSeq.sml`](https://github.com/MPLLang/delayed-seq/blob/main/ml/lib/NewDelayedSeq.sml).
  When compiling a benchmark, use `new-delay` for the cleaned-up library.
  (For example, `cd ml && make bfs.new-delay.mpl-latest.bin`.)
  * Small performance improvements to a few benchmarks.

## Setup

First, install [`mpl-switch`](https://github.com/MPLLang/mpl-switch).

Next, run the following to install versions of `mpl` needed for experiments.
This will take a long time.
```
$ ./init
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
of the form `BENCH.IMPL.CONFIG.bin`, for example `mcss.array.mpl.bin` and
`primes.delay.cpp.bin`.

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
