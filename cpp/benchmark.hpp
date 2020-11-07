#pragma once

#include <algorithm>

#include "cppdelayed/parlay/sequence.h"
#include "cppdelayed/parlay/primitives.h"
#include "cppdelayed/parlay/parallel.h"
#include "cppdelayed/parlay/monoid.h"
#include "benchmarkShared.hpp"

namespace pbbsBench {

static
void cilk_set_nb_workers(int nb_workers) {
#if defined(PARLAY_CILK)                  
  int cilk_failed = __cilkrts_set_param("nworkers", std::to_string(nb_workers).c_str());
  if (cilk_failed) {
    printf("failed\n");
  }
#endif
}
  
void setProc(int nb_proc) {
#ifndef HOMEGROWN
  cilk_set_nb_workers(nb_proc);
#endif
}
  
void warmup(int nb_proc) {
  size_t dflt_warmup_n = (nb_proc == 1) ? 5 : 35;
  size_t warmup_n = deepsea::cmdline::parse_or_default_int("warmup", dflt_warmup_n);
  for (int i = 0; i < warmup_n; i++) {
    size_t n = 100000000;
    auto A = parlay::tabulate(n, [] (size_t i) -> double {return 1.0;});
  }
}
    
} // end namespace
