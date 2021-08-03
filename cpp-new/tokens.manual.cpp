#include "cmdline.hpp"
#include "benchmark.hpp"
#include "cppdelayed/tokens.h"

int main(int argc, char** argv) {
  size_t n = std::max((size_t)1, (size_t)deepsea::cmdline::parse_or_default_long("n", 1000000000));
  auto str = parlay::tabulate(n, [] (size_t i) -> char {
    return (i%8 == 0) ? ' ' : 'a';});
  auto is_space = [] (char c) {
    switch (c)  {
    case '\r': case '\t': case '\n': case ' ' : return true;
    default : return false;
    }
  };
  using ipair = std::pair<long,long>;
  size_t s;
  pbbsBench::launch([&] {
    auto xd = parlay::tokens(str, is_space);
    s = xd.size();
  });
  cout << "result " << s << endl;
  return 0;
}
