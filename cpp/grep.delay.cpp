#include "cmdline.hpp"
#include "benchmark.hpp"
#include "cppdelayed/scan_delayed.h"
#include "cppdelayed/parlay/sequence.h"
#include "cppdelayed/parlay/primitives.h"
#include "cppdelayed/parlay/parallel.h"
#include "cppdelayed/parlay/monoid.h"
#include "cppdelayed/parlay/utilities.h"
#include "cppdelayed/parlay/io.h"

auto grep(parlay::range<char*> str, parlay::sequence<char>& search_str) -> parlay::sequence<char> {
  auto is_even = [] (size_t i) { return i & 1; };
  auto is_line_break = [&] (char a) {return a == '\n';};
  auto cr = singleton('\n');
  auto lines = parlay::filter(parlay::split_range(str, is_line_break), [&] (auto const &s) {
      return parlay::search(s, search_str) < s.size();});
  return parlay::flatten(parlay::tabulate(lines.size()*2, [&] (size_t i) {
      return is_even(i) ? cr : lines[i/2];}));
}

using namespace std;

int main(int argc, char** argv) {
  auto infile = deepsea::cmdline::parse_or_default_string("infile", "grep.txt");
  auto pattern_str = deepsea::cmdline::parse_or_default_string("pattern", "xxy");
  auto pattern = parlay::tabulate(pattern_str.size(), [&] (size_t i) { return pattern_str[i]; });
  auto input = parlay::chars_from_file(infile.c_str(), true);
  auto str = parlay::make_range(input.begin(), input.end());
  parlay::sequence<char> out_str;
  pbbsBench::launch([&] {
    out_str = grep(str, pattern);
  });
  std::cout << "result " << out_str.size() << std::endl;
  return 0;
}