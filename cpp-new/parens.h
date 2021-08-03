#pragma once

#include <iostream>
#include <cassert>
#include "benchmark.hpp"

bool paren_match_strict(parlay::sequence<char> const &str) {
  timer t("pm");
  auto lr = parlay::tabulate(str.size(), [&] (size_t i) -> long {
      return (str[i] == '(') ? 1 : (str[i] == ')') ? -1 : 0;
    });
  t.next("tabulate");
  auto sr = parlay::scan(lr, parlay::addm<long>());
  t.next("scan");
  long minv = parlay::reduce(sr.first, parlay::minm<long>());
  t.next("reduce");
  return (sr.second == 0) && (minv > 0);
}

bool paren_match_delayed_seq(parlay::sequence<char> const &str) {
  timer t("pm");
  auto lr = parlay::delayed_seq<long>(str.size(), [&] (size_t i) -> long {
      return (str[i] == '(') ? 1 : (str[i] == ')') ? -1 : 0;
    });
  auto sr = parlay::scan(lr, parlay::addm<long>());
  t.next("scan");
  long minv = parlay::reduce(sr.first, parlay::minm<long>());
  t.next("reduce");
  return (sr.second == 0) && (minv > 0);
}

bool paren_match_delayed(parlay::sequence<char> const &str) {
  timer t("pm");
  auto lr = parlay::delayed_seq<long>(str.size(), [&] (size_t i) -> long {
      return (str[i] == '(') ? 1 : (str[i] == ')') ? -1 : 0;
    });
  auto sr = parlay::block_delayed::scan(lr, parlay::addm<long>());
  t.next("delayed scan");
  long minv = parlay::block_delayed::reduce(sr.first, parlay::minm<long>());
  t.next("reduce");
  return (sr.second == 0) && (minv > 0);
}

bool paren_match_dc(parlay::sequence<char> const &str) {
  timer t("pm");
  auto lr = parlay::delayed_seq<long>(str.size(), [&] (size_t i) -> long {
      return (str[i] == '(') ? 1 : (str[i] == ')') ? -1 : 0;
    });
  auto sr = parlay::block_delayed::scan(lr, parlay::addm<long>());
  t.next("delayed scan");
  long minv = parlay::block_delayed::reduce(sr.first, parlay::minm<long>());
  t.next("reduce");
  return (sr.second == 0) && (minv > 0);
}

auto paren_match_reduce_delayed(parlay::sequence<char> const& str) {
  timer t("pm");
  using tu = std::pair<long,long>;
  auto f = [] (tu a, tu b) {
	     return ((a.second > b.first) ?
		     tu(a.first, a.second-b.first+b.second) :
		     tu(a.first-a.second+b.first, b.second));};
  auto pre = parlay::delayed_seq<tu>(str.size(), [&] (size_t i) -> tu {
		  return (str[i] == '(') ? tu(0,1) : (str[i] == ')') ? tu(1,0) : tu(0,0);
    });
  auto r = parlay::reduce(pre, parlay::make_monoid(f, tu(0,0)));
  return (r.first == 0) && (r.second == 0);
}

auto paren_match_reduce_strict(parlay::sequence<char> const& str) {
  timer t("pm");
  using tu = std::pair<long,long>;
  auto f = [] (tu a, tu b) {
	     return ((a.second > b.first) ?
		     tu(a.first, a.second-b.first+b.second) :
		     tu(a.first-a.second+b.first, b.second));};
  auto pre = parlay::tabulate(str.size(), [&] (size_t i) -> tu {
  	     return (str[i] == '(') ? tu(0,1) : (str[i] == ')') ? tu(1,0) : tu(0,0);
    });
  t.next("tabulate");
  auto r = parlay::reduce(pre, parlay::make_monoid(f, tu(0,0)));
  t.next("reduce");
  return (r.first == 0) && (r.second == 0);
}
