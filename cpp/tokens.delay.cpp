#include "cmdline.hpp"
#include "benchmark.hpp"
#include "cppdelayed/scan_delayed.h"
#include "cppdelayed/parlay/sequence.h"
#include "cppdelayed/parlay/primitives.h"
#include "cppdelayed/parlay/parallel.h"
#include "cppdelayed/parlay/monoid.h"

using namespace std;

template <class F, class Seq, class Idx_Type>
auto tokens(const F& f, Seq const& s)  {
  auto n = s.size();
  auto indices = parlay::delayed_seq<Idx_Type>(n+1, [&] (size_t i) { return i; });
  auto check = [&] (Idx_Type i) {
    if (i == n) {
      return ! (f(s[n-1]));
    } else if (i == 0) {
      return !(f(s[0]));
    } else {
      auto i1 = f(s[i]);
      auto i2 = f(s[i-1]);
      return (i1 && !i2) || (i2 && !i1);
    }
  };
  auto ids = parlay::filter(indices, check);
  return parlay::delayed_seq<parlay::sequence<Idx_Type>>(ids.size()/2, [&] (size_t i) {
    auto start = ids[2*i];
    auto e = ids[2*i+1];
    return parlay::tabulate(e-start, [&] (size_t j) { return ids[start+j]; });
  });
}

int main(int argc, char** argv) {
  size_t n = max((size_t)1, (size_t)deepsea::cmdline::parse_or_default_long("n", 100000000));
  auto A = parlay::tabulate(n, [] (size_t i) { return (char)(i % 20) + ' '; });
  auto isSpace = [] (char c) { return c == ' '; };
  size_t s;
  pbbsBench::launch([&] {
    auto R = tokens<decltype(isSpace),decltype(A),size_t>(isSpace, A);
    s = R.size();
  });
  cout << "result " << s << endl;
  return 0;
}
