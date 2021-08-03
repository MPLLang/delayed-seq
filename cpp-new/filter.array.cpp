#include "cmdline.hpp"
#include "benchmark.hpp"

template <typename Seq, typename F>
auto filter_strict(Seq const& A, F f) {
  timer t("filter");
  auto flags = parlay::tabulate(A.size(), [&] (size_t i) -> size_t {
      return f(A[i]);});
  t.next("tabulate");
  auto [offsets, sum] = parlay::scan(flags, parlay::addm<size_t>());
  t.next("scan");
  auto r = parlay::sequence<size_t>::uninitialized(sum);
  parlay::parallel_for(0, A.size(), [&] (size_t i) {
				      if (f(A[i])) r[offsets[i]] = A[i];});
  t.next("parallel_for");
  return r;
}

int main(int argc, char** argv) {
  size_t n = std::max((size_t)1, (size_t)deepsea::cmdline::parse_or_default_long("n", 100000000));
  auto A = parlay::block_delayed::force(parlay::iota(n));
  auto f = [] (size_t v) -> size_t {return (v % 2) == 0;};
  parlay::sequence<size_t> r;
  pbbsBench::launch([&] {
    r = filter_strict(A, f);
  });
  cout << "result " << r[0] << endl;
  return 0;
}

