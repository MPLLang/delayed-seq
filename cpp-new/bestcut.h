#include <parlay/sequence.h>

#include "pbbsbench/common/geometry.h"

#include "pbbsbench/rayCast/kdTree/ray.C"

cutInfo bestCutNoDelay(sequence<event> const &E, range r, range r1, range r2) {
  index_t n = E.size();
  if (n < minParallelSize)
    return bestCutSerial(E, r, r1, r2);
  double flt_max = std::numeric_limits<double>::max();
  if (r.max - r.min == 0.0) return cutInfo(flt_max, r.min, n, n);

  // area of two orthogonal faces
  float orthogArea = 2 * ((r1.max-r1.min) * (r2.max-r2.min));

  // length of the perimeter of the orthogonal faces
  float orthoPerimeter = 2 * ((r1.max-r1.min) + (r2.max-r2.min));

  // count number that end before i
  auto is_end = parlay::tabulate(n, [&] (index_t i) -> index_t {return IS_END(E[i]);});
  auto end_counts = parlay::scan_inclusive(is_end, parlay::addm<index_t>());
  
  // calculate cost of each possible split location, 
  // return tuple with cost, number of ends before the location, and the index
  using rtype = std::tuple<float,index_t,index_t>;
  
  auto costs = parlay::tabulate(n, [&](size_t i) {
    index_t num_ends = end_counts[i];
    index_t num_ends_before = num_ends - IS_END(E[i]); 
    index_t inLeft = i - num_ends_before; // number of points intersecting left
    index_t inRight = n/2 - num_ends;   // number of points intersecting right
    float leftLength = E[i].v - r.min;
    float leftSurfaceArea = orthogArea + orthoPerimeter * leftLength;
    float rightLength = r.max - E[i].v;
    float rightSurfaceArea = orthogArea + orthoPerimeter * rightLength;
    float cost = leftSurfaceArea * inLeft + rightSurfaceArea * inRight;
    return rtype(cost, num_ends_before, i);
  });

  // find minimum across all, returning the triple
  auto min_f = [&] (rtype a, rtype b) {return (std::get<0>(a) < std::get<0>(b)) ? a : b;};
  rtype identity(std::numeric_limits<float>::max(), 0, 0);
  auto [cost, num_ends_before, i] =
    parlay::reduce(costs, parlay::make_monoid(min_f, identity));
 
  index_t ln = i - num_ends_before;
  index_t rn = n/2 - (num_ends_before + IS_END(E[i]));
  return cutInfo(cost, E[i].v, ln, rn);
}

// Generate input data for the bestCut routine
sequence<event> generateInput(size_t n) {
  sequence<event> events(2*n);
  parlay::parallel_for(0, n, [&](size_t i) {
    events[i/2].p = i;
    events[i/2+1].p = i;
    events[i/2].v = i;
    events[i/2+1].v = i + 1;
  });
  return events;
}
