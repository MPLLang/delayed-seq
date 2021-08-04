#include <parlay/sequence.h>
#include <parlay/primitives.h>

#include "cmdline.hpp"
#include "benchmarkShared.hpp"

#include "pbbsbench/common/geometry.h"
#include "pbbsbench/common/geometryIO.h"
#include "pbbsbench/rayCast/bench/ray.h"
#include "pbbsbench/rayCast/kdTree/ray.C"

int main(int argc, char** argv) {
  auto triangles_file = deepsea::cmdline::parse_or_default_string("triangles", "");
  auto rays_file = deepsea::cmdline::parse_or_default_string("rays", "");
  
  // the 1 argument means that the vertices are labeled starting at 1
  triangles<point> T = readTrianglesFromFile<point>(triangles_file.c_str(), 1);
  parlay::sequence<point> Pts = readPointsFromFile<point>(rays_file.c_str());
  size_t n = Pts.size()/2;
  auto rays = parlay::tabulate(n, [&] (size_t i) -> ray<point> {
      return ray<point>(Pts[2*i], Pts[2*i+1]-point(0,0,0));});
  
  parlay::sequence<index_t> R;
  pbbsBench::launch([&] {
    R = rayCast(T, rays);
  });
}
