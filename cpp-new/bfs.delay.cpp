#include <parlay/sequence.h>

#include "cmdline.hpp"
#include "benchmarkShared.hpp"

#include "pbbsbench/common/graphIO.h"
#include "pbbsbench/breadthFirstSearch/bench/BFS.h"
#include "pbbsbench/breadthFirstSearch/simpleBFS/BFS.C"

int main(int argc, char** argv) {
  auto infile = deepsea::cmdline::parse_or_default_string("infile", "graph");
  
  Graph G = readGraphFromFile<vertexId,edgeId>(const_cast<char*>(infile.c_str()));
  G.addDegrees();
  
  sequence<vertexId> result;
  pbbsBench::launch([&] {
    result = BFS(0, G);
  });
}
