#include "cmdline.hpp"
#include "benchmark.hpp"

using namespace std;

template <class Seq>
std::tuple<size_t,size_t,size_t> wc(Seq const &s) {
  using P = std::pair<size_t,size_t>;

  // Create a delayed sequence of pairs of integers:
  // the first is 1 if it is line break, 0 otherwise;
  // the second is 1 if the start of a word, 0 otherwise.
  auto x = parlay::tabulate(s.size(), [&] (size_t i) {
      auto is_space = [] (char a) {
	return a == '\n' || a == '\t' || a == ' ';};
      bool is_line_break = s[i] == '\n';
      bool word_start = ((i == 0 || is_space(s[i-1])) &&
			 !is_space(s[i]));
      return P(is_line_break, word_start);
    });

  // Reduce summing the pairs to get total line breaks and words.
  // This is faster than summing them separately since that would
  // require going over the input sequence twice.
  auto r = parlay::reduce(x, parlay::pair_monoid(parlay::addm<size_t>(),parlay::addm<size_t>())); 

  return std::make_tuple(r.first, r.second, s.size());
}

int main(int argc, char** argv) {
  size_t n = max((size_t)1, (size_t)deepsea::cmdline::parse_or_default_long("n", 100000000));
  auto str = parlay::tabulate(n, [&] (size_t i) -> char { return parlay::hash64(i) % 255; });
  size_t lines, words, bytes;
  pbbsBench::launch([&] {
    tie(lines, words, bytes) = wc(str);
  });
  cout << "lines " << lines << endl;
  cout << "words " << words << endl;
  cout << "bytes " << bytes << endl;
  return 0;
}
