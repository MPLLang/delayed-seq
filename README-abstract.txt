This artifact accompanies the paper "Parallel Block-Delayed Sequences" at
PPoPP'22. The paper presents a library-only technique for fusing
collection-oriented operations (map, zip, filter, flatten, scan, etc.) which
improves both run-time and space usage by avoiding unnecessary intermediate
allocations. This artifact provides source code for libraries in both C++ and
Parallel ML, implementing block-delayed sequences. It also includes scripts to
run experiments and validate the results in the paper, supporting our claims
that block-delayed sequences provide significant improvements in both time
and space.
