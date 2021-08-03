#include "cmdline.hpp"
#include "benchmark.hpp"
#include "parens.h"

int main(int argc, char** argv) {
  size_t n = std::max((size_t)1, (size_t)deepsea::cmdline::parse_or_default_long("n", 100000000));
  parlay::sequence<char> str(n, 1);
  pbbsBench::launch([&] {
    paren_match_strict(str);
  });
  //  cout << "result " << result << endl;
  return 0;
}

