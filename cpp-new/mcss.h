#pragma once

#include <iostream>
#include <cassert>
#include "benchmark.hpp"

auto mcss_delayed_scan(parlay::sequence<double> const& A) {
  timer t("mcss");
  auto offsets = parlay::block_delayed::scan_inclusive(A, parlay::addm<double>());
  t.next("delayed scan");
  auto minprev = parlay::block_delayed::scan_inclusive(A, parlay::make_monoid(parlay::minm<double>().f, 0.0));
  t.next("delayed scan");
  auto z = parlay::block_delayed::zip(offsets,minprev);
  t.next("zip");
  auto diffs = parlay::block_delayed::map(z, [] (auto x) -> double {return x.first-x.second;});
  t.next("map");
  double r = parlay::block_delayed::reduce(diffs, parlay::maxm<double>());
  t.next("reduce");
  return r;
}

auto mcss_delayed_single_scan(parlay::sequence<double> const& A) {
  timer t("mcss");
  using dpair = std::pair<double,double>;
  auto f = [] (dpair a, dpair b) {
    return dpair(a.first + b.first, std::min(a.second, a.first+b.second));};
  auto g = parlay::make_monoid(f, dpair(0.0,0.0));
  auto pre = parlay::delayed_seq<dpair>(A.size(), [&] (size_t i) {
      return dpair(A[i],A[i]);});
  auto [x, total] = parlay::block_delayed::scan(pre, g);
  t.next("delayed scan");
  auto diffs = parlay::block_delayed::map(x, [] (dpair x) {return x.first - x.second;});
  t.next("map");
  double r = parlay::block_delayed::reduce(diffs, parlay::maxm<double>());
  t.next("reduce");
  return std::max(r, total.first - total.second) ;
}

auto mcss_strict_scan(parlay::sequence<double> const& A) {
  timer t("mcss");
  auto offsets = parlay::scan_inclusive(A, parlay::addm<double>());
  t.next("scan");
  auto minprev = parlay::scan_inclusive(A, parlay::make_monoid(parlay::minm<double>().f,0.0));
  t.next("scan");
  auto diffs = parlay::tabulate(A.size(), [&] (size_t i) -> double {
      return offsets[i] - minprev[i];});
  t.next("tabulate");
  double r = parlay::reduce(diffs, parlay::maxm<long>());
  t.next("reduce");
  return r;
}

auto mcss_delayed_reduce(parlay::sequence<double> const& A) {
  timer t("mcss");
  using tu = std::array<double,4>;
  auto f = [] (tu a, tu b) {
    tu r = {std::max(std::max(a[0],b[0]),a[2]+b[1]),
	    std::max(a[1],a[3]+b[1]),
	    std::max(a[2]+b[3],b[2]),
	    a[3]+b[3]};
    return r;};
  double neginf = std::numeric_limits<double>::lowest();
  tu identity = {neginf, neginf, neginf, (double) 0.0};
  auto pre = parlay::delayed_seq<tu>(A.size(), [&] (size_t i) -> tu {
      tu x = {A[i],A[i],A[i],A[i]};
      return x;
    });
  auto r = parlay::reduce(pre, parlay::make_monoid(f, identity));
  t.next("reduce");
  return r[0];
}

auto mcss_delayed_scan_all(parlay::sequence<double> const& A) {
  timer t("mcss");
  using tu = std::array<double,4>;
  auto f = [] (tu a, tu b) {
    tu r = {std::max(std::max(a[0],b[0]),a[2]+b[1]),
	    std::max(a[1],a[3]+b[1]),
	    std::max(a[2]+b[3],b[2]),
	    a[3]+b[3]};
    return r;};
  double neginf = std::numeric_limits<double>::lowest();
  tu identity = {neginf, neginf, neginf, (double) 0.0};
  auto pre = parlay::delayed_seq<tu>(A.size(), [&] (size_t i) -> tu {
      tu x = {A[i],A[i],A[i],A[i]};
      return x;
    });
  auto [x, total] = parlay::block_delayed::scan(pre, parlay::make_monoid(f, identity));
  t.next("scan");
  auto r = parlay::block_delayed::force(parlay::block_delayed::map(x, [] (tu a) {return a[0];}));
  t.next("map and force");
  return r;
}

auto mcss_strict_scan_all(parlay::sequence<double> const& A) {
  timer t("mcss");
  using tu = std::array<double,4>;
  auto f = [] (tu a, tu b) {
    tu r = {std::max(std::max(a[0],b[0]),a[2]+b[1]),
	    std::max(a[1],a[3]+b[1]),
	    std::max(a[2]+b[3],b[2]),
	    a[3]+b[3]};
    return r;};
  double neginf = std::numeric_limits<double>::lowest();
  tu identity = {neginf, neginf, neginf, (double) 0.0};
  auto pre = parlay::tabulate(A.size(), [&] (size_t i) -> tu {
      tu x = {A[i],A[i],A[i],A[i]};
      return x;
    });
  auto [x, total] = parlay::scan(pre, parlay::make_monoid(f, identity));
  t.next("scan");
  auto r = parlay::map(x, [] (tu a) {return a[0];});
  t.next("map and force");
  return r;
}

auto mcss_strict_reduce(parlay::sequence<double> const& A) {
  timer t("mcss");
  using tu = std::array<double,4>;
  auto f = [] (tu a, tu b) {
    tu r = {std::max(std::max(a[0],b[0]),a[2]+b[1]),
	    std::max(a[1],a[3]+b[1]),
	    std::max(a[2]+b[3],b[2]),
	    a[3]+b[3]};
    return r;};
  double neginf = std::numeric_limits<double>::lowest();
  tu identity = {neginf, neginf, neginf, 0.0};
  auto pre = parlay::tabulate(A.size(), [&] (size_t i) -> tu {
      tu x = {A[i],A[i],A[i],A[i]};
      return x;
    });
  t.next("tabulate");
  auto r = parlay::reduce(pre, parlay::make_monoid(f, identity));
  t.next("reduce");
  return r[0];
}
