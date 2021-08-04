#include <iostream>
#include <algorithm>
#include "benchmark.hpp"
#include "pbbsbench/common/geometry.h"
#include "pbbsbench/common/geometryIO.h"
#include "pbbsbench/convexHull/quickHull/hull.h"

using namespace std;

//#include "serialHull.h"

// The quickhull algorithm
// Points are all the points
// Idxs are the indices of the points (in Points) above the line defined by l--r.
// mid gives the index of the point furthest from the line defined by l--r
// The algorithm identifies the points above the lines l--mid and mid--r
//   and recurses on each
parlay::sequence<indexT> quickHull(parlay::sequence<point> const & Points,
				   parlay::sequence<indexT> Idxs,
				   indexT l, indexT mid, indexT r) {
  size_t n = Idxs.size();
  if (n <= 1) return Idxs;
  //  serialQuickHull is slightly faster for the base case, but not as clean
  //if (n <= 10000) { 
  //  size_t r = serialQuickHull(Idxs.begin(), Points.begin(), n, l, r);
  //  return parlay::sequence<indexT>(r, [&] (size_t i) {return Idxs[i];});}
  else {
    using cipair = std::pair<coord,indexT>;
    using cipairs = std::pair<cipair,cipair>;
    auto pairMax = [&] (cipairs a, cipairs b) {
      return cipairs((a.first.first > b.first.first) ? a.first : b.first,
		     (a.second.first > b.second.first) ? a.second : b.second);};

    // calculate furthest (positive) points from the lines l--mid and mid--r
    // at the same time set flags for those which are above each line
    auto leftFlag = parlay::sequence<bool>::uninitialized(n) ;
    auto rightFlag = parlay::sequence<bool>::uninitialized(n) ;

    point lP = Points[l], midP = Points[mid], rP = Points[r];
    auto P = parlay::tabulate(n, [&] (size_t i) {
	indexT j = Idxs[i];
	coord lefta = triArea(lP, midP, Points[j]);
	coord righta = triArea(midP, rP, Points[j]);
	leftFlag[i] = lefta > 0.0;
	rightFlag[i] = righta > 0.0;
	return cipairs(cipair(lefta,j),cipair(righta,j));
      });
    cipairs prs = parlay::reduce(P, parlay::make_monoid(pairMax,cipairs()));
    indexT maxleft = prs.first.second;
    indexT maxright = prs.second.second;

    // keep those above each line
    parlay::sequence<indexT> left = parlay::pack(Idxs, leftFlag);
    parlay::sequence<indexT> right = parlay::pack(Idxs, rightFlag);
    Idxs.clear(); // clear and use std::move to avoid O(n log n) memory usage

    // recurse in parallel
    parlay::sequence<indexT> leftR, rightR;
    parlay::par_do_if(n > 400,
	      [&] () {leftR = quickHull(Points, std::move(left), l, maxleft, mid);},
	      [&] () {rightR = quickHull(Points, std::move(right), mid, maxright, r);});
    
    // append the results together with mid in the middle
    parlay::sequence<indexT> result(leftR.size() + rightR.size() + 1);
    auto xxx = result.head(leftR.size());
    parlay::copy(leftR, xxx);
    result[leftR.size()] = mid;
    auto yyy = result.cut(leftR.size() + 1, result.size());
    parlay::copy(rightR, yyy);
    return result;
  }
}

// The top-level call has to find the maximum and minimum x coordinates
//   and use them for the initial lines minp--maxp (for the upper hull)
//   and maxp--minp (for the lower hull).
parlay::sequence<indexT> hull(parlay::sequence<point> const &Points) {
  timer t("hull", false);
  size_t n = Points.size();
  auto pntless = [&] (point a, point b) {
    return (a.x < b.x) || ((a.x == b.x) && (a.y < b.y));};

  // min and max points by x coordinate
  auto minmax = parlay::minmax_element(Points, pntless);
  auto min_x_idx = minmax.first - std::begin(Points);
  auto max_x_idx = minmax.second - std::begin(Points);
  t.next("minmax");

  // identify those above and below the line minp--maxp
  // and calculate furtherst in each direction
  auto upperFlag = parlay::sequence<bool>::uninitialized(n) ;
  auto lowerFlag = parlay::sequence<bool>::uninitialized(n) ;
  auto P = parlay::tabulate(n, [&] (size_t i) {
    coord a = triArea(Points[min_x_idx], Points[max_x_idx], Points[i]);
    upperFlag[i] = a > 0;
    lowerFlag[i] = a < 0;
    return a;
    });

  auto max_lower_upper = parlay::minmax_element(P, std::less<coord>());
  size_t max_lower_idx = max_lower_upper.first - std::begin(P);
  size_t max_upper_idx = max_lower_upper.second - std::begin(P);
  
  t.next("flags");

  // pack the indices of those above and below
  parlay::sequence<indexT> upper = parlay::internal::pack_index<indexT>(upperFlag);
  parlay::sequence<indexT> lower = parlay::internal::pack_index<indexT>(lowerFlag);
  t.next("pack");

  // make parallel calls for upper and lower hulls
  parlay::sequence<indexT> upperR, lowerR;
  parlay::par_do(
	 [&] () {upperR = quickHull(Points, std::move(upper),
				    min_x_idx, max_upper_idx, max_x_idx);},
	 [&] () {lowerR = quickHull(Points, std::move(lower),
				    max_x_idx, max_lower_idx, min_x_idx);}
	 );
  t.next("recurse");
    
  parlay::sequence<indexT> result(upperR.size() + lowerR.size() + 2);
  result[0] = min_x_idx;
  auto xxx = result.cut(1, 1 + upperR.size());
  parlay::copy(upperR, xxx);
  result[1 + upperR.size()] = max_x_idx;
  auto yyy = result.cut(upperR.size() + 2, result.size());
  parlay::copy(lowerR, yyy);
  t.next("append");
  return result;
}

using namespace std;

using coord = double;
using point = point2d<coord>;

int main(int argc, char** argv) {
  auto infile = deepsea::cmdline::parse_or_default_string("infile", "points.txt");
  parlay::sequence<point> Points = readPointsFromFile<point>(infile.c_str());
  indexT r;
  pbbsBench::launch([&] {
    parlay::sequence<indexT> I = hull(Points);
    r = I[0];
  });
  std::cout << "result " << r << std::endl;
  return 0;
}