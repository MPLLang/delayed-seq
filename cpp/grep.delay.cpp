#include "cmdline.hpp"
#include "benchmark.hpp"
#include "cppdelayed/scan_delayed.h"
#include "cppdelayed/parlay/sequence.h"
#include "cppdelayed/parlay/primitives.h"
#include "cppdelayed/parlay/parallel.h"
#include "cppdelayed/parlay/monoid.h"
#include "cppdelayed/parlay/utilities.h"
#include "cppdelayed/parlay/io.h"

auto grep(parlay::sequence<char> const &str,
	  parlay::sequence<char> const &search_str){
  auto is_even = [] (size_t i) { return i & 1; };
  auto is_line_break = [&] (char a) {return a == '\n';};
  auto identity = [] (auto x) {return x;};
  auto cr = parlay::sequence<char>('\n',1);
  auto lines = parlay::filter(parlay::map_tokens(str, identity, is_line_break),
			      [&] (auto const &s) {
      return parlay::search(s, search_str) < s.end();});
  auto s = parlay::delayed_seq<parlay::sequence<char>>(lines.size()*2, [&] (size_t i) {
    return is_even(i) ? cr : parlay::to_sequence(lines[i/2]);});
  return delayed::flatten(s);
}

using namespace std;

int main(int argc, char** argv) {
  auto infile = deepsea::cmdline::parse_or_default_string("infile", "grep.txt");
  auto pattern_str = deepsea::cmdline::parse_or_default_string("pattern", "xxy");
  auto pattern = parlay::tabulate(pattern_str.size(), [&] (size_t i) { return pattern_str[i]; });
  auto input = parlay::chars_from_file(infile.c_str(), true);
  size_t result;
  pbbsBench::launch([&] {
    auto out_str = grep(input, pattern);
    result = out_str.size();
  });
  std::cout << "result " << result << std::endl;
  return 0;
}
