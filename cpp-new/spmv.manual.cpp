#include "cmdline.hpp"
#include "benchmark.hpp"
#include "cppdelayed/scan_delayed.h"
#include "cppdelayed/parlay/sequence.h"
#include "cppdelayed/parlay/primitives.h"
#include "cppdelayed/parlay/parallel.h"
#include "cppdelayed/parlay/monoid.h"

using namespace std;

// multiply a compresses sparse row matrix
template <class IntSeq, class Seq, class Rng, class Mult, class Add>
void mat_vec_mult(IntSeq const &starts,
		IntSeq const &columns,
		Seq const &values,
		Seq const &in,
		Rng out,
		Mult mult,
		Add add) {
  using E = typename Seq::value_type;
  size_t n = in.size();
  auto row_f = [&] (size_t i) {
    size_t s = starts[i];
    size_t e = starts[i+1];
    if (e > s) {
      E sum = mult(in[columns[s]],values[s]);
      for (size_t j=s+1; j < e; j++)
      sum = add(sum,mult(in[columns[j]],values[j]));
      out[i] = sum;
    } else out[i] = 0;
  };
  parlay::parallel_for(0, n, row_f, parlay::granularity(n));
}

int main(int argc, char** argv) {
  using T = int64_t;
  auto hashFn = [] (T v) { return parlay::hash64(v); };
  using real_type = double;
  size_t n = max((size_t)1, (size_t)deepsea::cmdline::parse_or_default_long("n", 100000000));
  size_t rowLen = 100;
  size_t numRows = n / rowLen;
  parlay::sequence<real_type> vec(numRows, 1.0);
  auto gen = [&] (size_t i, size_t j) { return make_pair(hashFn((i * rowLen + j)) % numRows, 1.0); };
  auto mat = parlay::tabulate(numRows, [&] (size_t i) { return parlay::tabulate(rowLen, [&] (size_t j) { return gen(i, j); }); });
  // convert from sequence of sequences representation generated above to the representation
  // expected by mat_vec_mult
  parlay::sequence<size_t> Out;
  size_t sum;
  tie(Out, sum) = parlay::scan(parlay::tabulate(mat.size(), [&] (size_t i) { return mat[i].size(); }));
  auto m = sum;
  auto starts = parlay::tabulate(numRows+1, [&] (size_t i) { return (i < Out.size()) ? Out[i] : m; });
  parlay::sequence<T> values(m, (T)1.0);
  auto X = parlay::flatten(mat);
  auto columns = parlay::tabulate(m, [&] (size_t i) { return X[i].first; });
  parlay::sequence<real_type> result;
  parlay::sequence<T> in(numRows, (T) 1);
  parlay::sequence<T> out(numRows, (T) 0);
  auto add = [] (T a, T b) { return a + b;};
  auto mult = [] (T a, T b) { return a * b;};
  pbbsBench::launch([&] {
    mat_vec_mult(starts, columns, values, in, parlay::make_slice(out), mult, add);
  });
  cout << "result " << result[0] << endl;
  cout << "nb_rows " << numRows << endl;
  cout << "n " << n << endl;
  cout << "m " << m << endl;
  return 0;
}
