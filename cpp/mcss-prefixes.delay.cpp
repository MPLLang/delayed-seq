#include "cmdline.hpp"
#include "benchmark.hpp"
#include "cppdelayed/mcss.h"

int main(int argc, char** argv) {
  size_t n = std::max((size_t)1, (size_t)deepsea::cmdline::parse_or_default_long("n", 100000000));
  auto A = parlay::tabulate(n, [] (size_t i) -> double {return 1.0;});
  double result;
  pbbsBench::launch([&] {
    auto r = mcss_delayed_scan_all(A);
    result = r[0];
  });
  cout << "result " << result << endl;
  return 0;
}

