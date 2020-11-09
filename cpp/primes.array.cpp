#include "cmdline.hpp"
#include "benchmark.hpp"
#include "cppdelayed/primes.h"

int main(int argc, char** argv) {
  size_t n = std::max((size_t)1, (size_t)deepsea::cmdline::parse_or_default_long("n", 10000000));
  auto A = parlay::tabulate(n, [] (size_t i) -> double {return 1.0;});
  int result;  
  pbbsBench::launch([&] {
    auto rs = primes_strict(n);
    result = rs[0];
  });
  cout << "result " << result << endl;
  return 0;
}

