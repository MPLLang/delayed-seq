#include "cmdline.hpp"
#include "benchmark.hpp"
#include "cppdelayed/scan_delayed.h"
#include "cppdelayed/parlay/sequence.h"
#include "cppdelayed/parlay/primitives.h"
#include "cppdelayed/parlay/parallel.h"
#include "cppdelayed/parlay/monoid.h"

int main(int argc, char** argv) {
  size_t n = std::max((size_t)1, (size_t)deepsea::cmdline::parse_or_default_long("n", 100000000));
  auto A = delayed::force(parlay::iota(n));
  auto f = [] (size_t v) -> size_t {return (v % 2) == 0;};
  parlay::sequence<size_t> r;
  pbbsBench::launch([&] {
    r = parlay::filter(A, f);
  });
  cout << "result " << r[0] << endl;
  return 0;
}
