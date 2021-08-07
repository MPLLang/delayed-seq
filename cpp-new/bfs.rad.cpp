#include <parlay/sequence.h>

#include "cmdline.hpp"
#include "benchmarkShared.hpp"

#include "pbbsbench/common/graphIO.h"
#include "pbbsbench/breadthFirstSearch/bench/BFS.h"
#include "pbbsbench/breadthFirstSearch/simpleBFS/BFS.C"

parlay::sequence<vertexId> BFSRAD(vertexId start, const Graph &G, 
			       bool verbose = false) {
  size_t n = G.numVertices();
  auto parent = parlay::sequence<std::atomic<vertexId>>::from_function(n, [&] (size_t i) {
      return -1;});
  parent[start] = start;
  parlay::sequence<vertexId> frontier(1,start);

  while (frontier.size() > 0) {

    // get out edges of the frontier and flatten
    auto nested_edges = parlay::map(frontier, [&] (vertexId u) {
      return parlay::delayed_tabulate(G[u].degree, [&, u] (size_t i) {
        return std::pair(u, G[u].Neighbors[i]);});});
    auto edges = parlay::flatten(nested_edges);

    // keep the v from (u,v) edges that succeed in setting the parent array at v to u
    auto edge_f = [&] (auto u_v) {
      vertexId expected = -1;
      auto [u, v] = u_v;
      return (parent[v] == -1) && parent[v].compare_exchange_strong(expected, u);
    };
    
    frontier = parlay::map(parlay::filter(edges, edge_f), [](const auto& x) { return x.second; });
  }

  // convert from atomic to regular sequence
  return parlay::map(parent, [] (auto const &x) -> vertexId {
      return x.load();});
}

int main(int argc, char** argv) {
  auto infile = deepsea::cmdline::parse_or_default_string("infile", "graph");
  auto source = deepsea::cmdline::parse_or_default_long("source", 0);

  Graph G = readGraphFromFile<vertexId,edgeId>(const_cast<char*>(infile.c_str()));
  G.addDegrees();

  sequence<vertexId> result;
  pbbsBench::launch([&] { 
    result = BFSRAD(source, G);
  });

  long numVisited = 0;
  for (long i = 0; i < result.size(); i++) {
    if (result[i] != -1) numVisited++;
  }

  std::cout << "visited " << numVisited << std::endl;
}
