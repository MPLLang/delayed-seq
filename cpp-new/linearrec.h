#pragma once

#include <iostream>
#include <cassert>
#include "benchmark.hpp"

void linear_rec_delayed(parlay::sequence<std::pair<double,double>> const& A) {
  using dpair = std::pair<double,double>;
  timer t("lr");
  auto f = [] (dpair l, dpair r) {
    return dpair(l.first*r.first,l.second*r.first+r.second);};
  auto m = parlay::make_monoid(f,dpair(1.0,0.0));
  auto recs = parlay::block_delayed::scan_inclusive(A, m);
  t.next("delayed scan");
  auto diffs = parlay::block_delayed::map(recs, [] (dpair x) -> long {return x.second;});
  t.next("delayed map");
  auto r = parlay::block_delayed::force(diffs);
  t.next("force");
}

void linear_rec_strict(parlay::sequence<std::pair<double,double>> const& A) {
  using dpair = std::pair<double,double>;
  timer t("lr");
  auto f = [] (dpair l, dpair r) {
    return dpair(l.first*r.first,l.second*r.first+r.second);};
  auto m = parlay::make_monoid(f,dpair(1.0,0.0));
  auto recs = parlay::scan_inclusive(A, m);
  t.next("scan");
  auto diffs = parlay::map(recs, [] (dpair x) -> long {return x.second;});
  t.next("map");
}
