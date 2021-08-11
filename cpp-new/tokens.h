#pragma once

#include <iostream>
#include <cassert>
#include "benchmark.hpp"


template <typename F>
auto tokens_delayed(parlay::sequence<char> const& A, F is_space) {
  timer t("tokens");
  using ipair = std::pair<long,long>;
  size_t n = A.size();
  auto is_start = [&] (size_t i) {
    return ((i == 0) || is_space(A[i-1])) && !(is_space(A[i]));};
  auto is_end = [&] (size_t i) {
    return  ((i == n) || (is_space(A[i]))) && (i != 0) && !is_space(A[i-1]);};
  // associative combining function
  // first = # of starts, second = index of last start
  auto f = [] (ipair a, ipair b) { 
    return (b.first == 0) ? a : ipair(a.first+b.first,b.second);};

  auto in = parlay::delayed_seq<ipair>(n+1, [&] (size_t i) -> ipair {
      return is_start(i) ? ipair(1,i) : ipair(0,0);});
  auto [offsets, sum] = parlay::block_delayed::scan(in, parlay::make_monoid(f,ipair(0,0)));
  t.next("delayed scan");

  auto z = parlay::block_delayed::zip(offsets, parlay::iota(n+1));

  t.next("zip");
  auto r = parlay::sequence<ipair>::uninitialized(sum.first);
  parlay::block_delayed::apply(z, [&] (auto x) {
    if (is_end(x.second))
      r[x.first.first] = ipair(x.first.second, x.second);});
  t.next("apply");
  return r;
}

template <typename F>
auto tokens_strict(parlay::sequence<char> const& str, F is_space){
  timer t("tokens");
  using ipair = std::pair<long,long>;
  size_t n = str.size();
  auto check = [&] (size_t i) {
    if (i == n) return is_space(str[n-i]);
    else if (i == 0) return !is_space(str[0]);
    else {
      bool i1 = is_space(str[i]);
      bool i2 = is_space(str[i-1]);
      return (i1 && !i2) || (i2 && !i1);
    }};
  auto idxs = parlay::to_sequence(parlay::iota(n+1));
  auto ids = parlay::filter(idxs, check);
  t.next("filter");
  auto res = parlay::tabulate(ids.size()/2, [&] (size_t i) {
      return ipair(ids[2*i],ids[2*i+1]);});
  t.next("tabulate");
  return res;
}

template <typename F>
auto tokens_rad(parlay::sequence<char> const& str, F is_space){
  timer t("tokens");
  using ipair = std::pair<long,long>;
  size_t n = str.size();
  auto check = [&] (size_t i) {
    if (i == n) return is_space(str[n-i]);
    else if (i == 0) return !is_space(str[0]);
    else {
      bool i1 = is_space(str[i]);
      bool i2 = is_space(str[i-1]);
      return (i1 && !i2) || (i2 && !i1);
    }};
  auto ids = parlay::filter(parlay::iota(n+1), check);
  t.next("filter");
  auto res = parlay::tabulate(ids.size()/2, [&] (size_t i) {
      return ipair(ids[2*i],ids[2*i+1]);});
  t.next("tabulate");
  return res;
}
