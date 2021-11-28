------------------------------------------------------------------------------
-------------------------------- INTRODUCTION --------------------------------
------------------------------------------------------------------------------

This artifact accompanies the paper "Parallel Block-Delayed Sequences" at
PPoPP'22. The paper presents a library-only technique for fusing
collection-oriented operations (map, zip, filter, flatten, scan, etc.) which
improves both run-time and space usage by avoiding unnecessary intermediate
allocations. The proposed technique consists of two forms: a "random-access
delayed" (RAD) representation which is similar to prior work, and a novel
"block-iterable delayed" (BID) representation which splits sequences into many
equal-sized blocks, where each block is a delayed stream.

------------------------------------------------------------------------------
----------------------------------- CLAIMS -----------------------------------
------------------------------------------------------------------------------

The claims in the paper supported by this artifact include:
  1. Block-delayed sequences can be efficiently implemented as libraries,
  with no compiler extensions, in both C++ and Parallel ML.
  2. At scale (on 72 processors), in comparison to a standard library with
  no fusion, block-delayed sequences are up to 19x faster with up to 93x
  less space.
  3. At scale, in comparison to RAD-only fusion, the new BID representation
  provides run-time improvements from 1.1 to 2.7x, and similarly provides
  space improvements from 1.1 to 10x.

------------------------------------------------------------------------------
---------------------------------- OVERVIEW ----------------------------------
------------------------------------------------------------------------------

The artifact is a self-contained Docker (www.docker.com) image containing all
code and scripts necessary for reproducing our results. In particular, this
includes source code for our library implementations of block-delayed sequences
as well as all benchmarks used in evaluation, and also all experiment scripts.
These are described in detail in the "Reuse and Repurposing" section, below.

For evaluating the artifact, we provide two sets of instructions, one for a
"small" evaluation, and the other for a "full" evaluation. The small evaluation
considers just a few benchmarks with reduced problem sizes, and takes about 5
minutes to run. The full evaluation is intended for fully reproducing our
results in the paper, and takes between 4.5 and 10 hours to run (depending
on how much is reproduced).

Minimum hardware requirements:
- 6GB RAM, 8 cores for the SMALL evaluation.
- 100GB RAM, >=32 cores for the FULL evaluation.

------------------------------------------------------------------------------
------------------------------ GETTING STARTED -------------------------------
------------------------------------------------------------------------------

Step 1: Download docker image. The image is packaged as part of this artifact,
and is also available from Docker Hub:

  $ sudo docker pull shwestrick/ppopp22-artifact

For the rest of the instructions, we assume the arifact is locally tagged
"shwestrick/ppopp22-artifact"


Step 2: Start the container. First, make a local directory 'ARTIFACT-RESULTS'
which will be mounted in the docker container (this lets us copy files out of
the container). Then start the container as shown below. This opens a bash
shell inside the container, which has the prompt '#'.

  $ mkdir ARTIFACT-RESULTS
  $ sudo docker run -v $(pwd -P)/ARTIFACT-RESULTS:/ARTIFACT-RESULTS --privileged --rm -it shwestrick/ppopp22-artifact /bin/bash

Note: the '--privileged' flag is necessary for NUMA control in the experiments.

------------------------------------------------------------------------------
-------------------------- STEP BY STEP EVAULATIONS --------------------------
------------------------------------------------------------------------------

SMALL EVALUATION (5 minutes)
----------------------------

Requires at least 6GB RAM and 8 cores.

Step 1: Run benchmarks. Run the following commands inside the container
(the prompt inside the container is '#').

  # ./run-small
  # ./report-small | tee /ARTIFACT-RESULTS/small-output
  # cp -r small/figures /ARTIFACT-RESULTS/small-figures

Step 2: Check results. The output of step 3 consists of tables (printed to
stdout, and copied to ARTIFACT-RESULTS/small-output) and a few speedup
plots (copied to ARTIFACT-RESULTS/small-figures).
  - The tables (ARTIFACT-RESULTS/small-output) are comparable to Figures 9 and
  10 in the paper, except with two important differences: the problem sizes are
  reduced by a factor 10, and only 8 cores are used (as opposed to 72 in the
  paper). The reported improvement ratios (R/Ours and A/Ours) therefore will
  not be exactly the same as in the paper, but should still generally be larger
  than 1, indicating improvement (speedup or reduced space usage).
  - The speedup plots (ARTIFACT-RESULTS/small-figures/*) are named respectively
      * mpl-cc-XXX-speedups.pdf: MPL (Parallel ML) results on benchmark XXX
      * cpp-XXX-speedups.pdf: C++ results on benchmark XXX
  The speedup plots should show that the 'delay' version (our full library)
  scales consistently better than both the 'array' (no fusion) and 'rad'
  (RAD-only) versions. These are similar to Figure 11 in the paper, but
  on only a small number of cores. The speedups will not be as high due to
  the reduced problem size and smaller number of cores used.

FULL EVALUATION (4.5-10 hours, optional)
----------------------------------------

Requires at least 100GB RAM and a large number of cores.
(At least 32 cores is okay; 64 or more is preferable).

Step 1: Generate inputs (~2 minutes).

  # ./generate-inputs

Step 2: Full experiments. Run the following commands inside the container.

  # ./run --procs <PROCLIST>
  # ./report | tee /ARTIFACT-RESULTS/full-output
  # cp -r figures /ARTIFACT-RESULTS/full-figures

The `run` script takes an argument `--procs <PROCLIST>` which is a
comma-separated (no spaces) list of processor counts to consider. We recommend
choosing a maximum number of processors corresponding to physical cores, to
avoid complications with hyperthreading. We also recommend choosing a range
of intermediate processor counts, to see informative speedup curves.

For example, in the paper we used `--procs 1,10,20,30,40,50,60,72` on a
machine with 72 physical cores. With 32 cores, we would recommend
`--procs 1,10,20,32`. With 64 cores, we recommend `--procs 1,10,20,30,40,50,64`.

For reference, on our machine, the command `./run --procs 1,72` takes 4.5
hours. This is the minimum required for reproducing Figures 9 and 10 in the
paper.

Step 3: Check results. Similar to the small evaluation, the tables produced
(ARTIFACT-RESULTS/full-output) are comparable to Figures 9 and 10, and the
speedup plots (ARTIFACT-RESULTS/full-figures) are comparable to Figure 11. If
a large number of processors (>=64) were used, the reported improvement ratios
(R/Ours and A/Ours) should be similar to those reported in the paper, modulo
hardware differences and containerization overheads.

-----------------------------------------------------------------------------
--------------------------- REUSE AND REPURPOSING ---------------------------
-----------------------------------------------------------------------------

The source code (library, benchmarks, and experiment scripts) used in the
artifact can easily be adapted for other uses. All code is additionally
available on GitHub (https://github.com/MPLLang/delayed-seq).

At a high level, there are two sets of source codes:
  cpp-new/ contains all C++ code
  ml/ contains all Parallel ML code.

In cpp-new/, each benchmark source is named `BENCHMARK.VERSION.cpp` where
VERSION is either 'array' (no fusion), 'rad' (RAD-only fusion), or 'delay'
(full fusion, i.e. both RAD and BID). The definition of the library codes are
in cpp-new/pbbsbench/parlaylib, which is a checkout of the ParlayLib
(https://github.com/cmuparlay/parlaylib) framework. The delayed sequences
as described in the paper have been incorporated into this framework.

In ml/, the subdirectory bench/ contains one folder for each version
(array, rad, and delay) and these folders respectively each have a
`sources.mlb` for compilation. The definition of the library codes are in
ml/lib/.

There are two primary Makefiles: cpp-new/Makefile and ml/Makefile. The former
has targets of the form `BENCHMARK.VERSION.cpp.bin` and the latter has targets
of the form `BENCHMARK.VERSION.mpl-v02.bin`. When making a benchmark, the
resulting binary is placed in a bin/ subdirectory (cpp-new/bin and ml/bin).

The cpp binaries all can be run with the following syntax, where <N> is the
number of threads to use, <ARGS> are benchmark-specific arguments, <R> is the
number of repetitions, and <W> is the length in seconds of the warmup period.
The warmup is performed by running the benchmark back-to-back until the warmup
period has expired, and then again back-to-back for the number of repetitions
specified.

  [delayed-seq/cpp-new]$ PARLAY_NUM_THREADS=<N> bin/<BENCHMARK>.<VERSION>.cpp.bin <ARGS> -repeat <R> -warmup <W>

The ml binaries are similar, but with slightly different syntax:

  [delayed-seq/ml]$ bin/<BENCHMARK>.<VERSION>.mpl-v02.bin @mpl procs <N> -- <ARGS> -repeat <R> -warmup <W>

In the top-level folder, the JSON files specifies the experiments. These
specifications are used by `scripts/gencmds` to produce "rows" of key-value
pairs, where each row describes one experiment. Examples of keys include
"config", "tag", "impl", etc. The config is either "cpp" or "mpl-v02", the
tag is the benchmark name, the impl is the version of the library used, etc.

The output of `scripts/gencmds` is then piped into `scripts/runcmds` to
produce results. See the `run` script for more detail.

Finally, the script `report` parses the results and produces tables and
figures.
