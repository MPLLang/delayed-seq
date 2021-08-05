#include <parlay/sequence.h>

#include "cmdline.hpp"
#include "benchmarkShared.hpp"

#include "pbbsbench/common/graphIO.h"
#include "pbbsbench/breadthFirstSearch/bench/BFS.h"
#include "pbbsbench/breadthFirstSearch/ndBFS/BFS.C"

int main(int argc, char** argv) {
  auto infile = deepsea::cmdline::parse_or_default_string("infile", "graph");
  auto source = deepsea::cmdline::parse_or_default_long("source", 0);

  Graph G = readGraphFromFile<vertexId,edgeId>(const_cast<char*>(infile.c_str()));
  G.addDegrees();

  std::pair<vertexId,size_t> result;
  pbbsBench::launch([&] {
    result = BFS(source, G);
  });

  std::cout << "visited " << result.first << std::endl;
  std::cout << "rounds " << result.second << std::endl;
}
