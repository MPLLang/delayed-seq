#include <parlay/sequence.h>

#include "pbbsbench/common/geometry.h"

#include "pbbsbench/rayCast/kdTree/ray.C"

cutInfo bestCutRAD(sequence<event> const &E, range r, range r1, range r2) {
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
  auto is_end = parlay::delayed_tabulate(n, [&] (index_t i) -> index_t {return IS_END(E[i]);});
  auto end_counts = parlay::scan_inclusive(is_end, parlay::addm<index_t>());
  
  // calculate cost of each possible split location, 
  // return tuple with cost, number of ends before the location, and the index
  using rtype = std::tuple<float,index_t,index_t>;
  auto costs = parlay::delayed_tabulate(n, [&](size_t i) {
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

cutInfo bestCutStreamOfBlocks(sequence<event> const &E, range r, range r1, range r2) {
  size_t block_size = 1000000;
  index_t n = E.size();
  if (n < minParallelSize)
    return bestCutSerial(E, r, r1, r2);
  double flt_max = std::numeric_limits<double>::max();
  if (r.max - r.min == 0.0) return cutInfo(flt_max, r.min, n, n);

  // area of two orthogonal faces
  float orthogArea = 2 * ((r1.max-r1.min) * (r2.max-r2.min));

  // length of the perimeter of the orthogonal faces
  float orthoPerimeter = 2 * ((r1.max-r1.min) + (r2.max-r2.min));

  size_t offset = 0;
  index_t scan_val = 0;
  using rtype = std::tuple<float,index_t,index_t>;
  rtype identity(std::numeric_limits<float>::max(), 0, 0);
  rtype result = identity;
      
  for (int j=0; offset < n; offset += block_size) {

    // trim last block
    size_t bsize = std::min(block_size, n - offset);
    
    // count number that end before i
    auto is_end = parlay::tabulate(bsize, [&] (index_t i) -> index_t {return IS_END(E[i+offset]);});
    auto plus = [] (index_t a, index_t b) {return a + b;};
    auto end_counts = parlay::scan_inclusive(is_end, parlay::make_monoid(plus, scan_val));
    scan_val = end_counts[bsize-1];
  
    // calculate cost of each possible split location, 
    // return tuple with cost, number of ends before the location, and the index
    auto costs = parlay::tabulate(bsize, [&](size_t ii) {
	index_t num_ends = end_counts[ii];
	size_t i = ii + offset;
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
    auto sum = parlay::reduce(costs, parlay::make_monoid(min_f, identity));
    auto result = min_f(result, sum);
  }
  auto [cost, num_ends_before, i] = result;
  index_t ln = i - num_ends_before;
  index_t rn = n/2 - (num_ends_before + IS_END(E[i]));
  return cutInfo(cost, E[i].v, lon, rn);
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
