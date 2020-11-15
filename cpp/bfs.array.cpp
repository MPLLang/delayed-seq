#include "cmdline.hpp"
#include "benchmark.hpp"
#include "cppdelayed/bfs.h"
#include "pbbsbench/common/IO.h"

using namespace std;

string AdjGraphHeader = "AdjacencyGraph";
string EdgeArrayHeader = "EdgeArray";
string WghEdgeArrayHeader = "WeightedEdgeArray";
string WghAdjGraphHeader = "WeightedAdjacencyGraph";

graph readGraphFromFile(char* fname) {
  parlay::sequence<char> S = benchIO::readStringFromFile(fname);
  parlay::sequence<char*> W = benchIO::stringToWords(S);
  if (W[0] != AdjGraphHeader) {
    cout << "Bad input file: missing header: " << AdjGraphHeader << endl;
    abort();
  }

  // file consists of [type, num_vertices, num_edges, <vertex offsets>, <edges>]
  // in compressed sparse row format
  long n = atol(W[1]);
  long m = atol(W[2]);
  if (W.size() != n + m + 3) {
    cout << "Bad input file: length = "<< W.size() << " n+m+3 = " << n+m+3 << endl;
    abort(); }
    
  // tags on m at the end (so n+1 total offsets)
  auto offsets = parlay::tabulate(n+1, [&] (size_t i) -> vtx {
    return (i == n) ? m : atol(W[i+3]);});
  auto edges = parlay::tabulate(m, [&] (size_t i) -> vtx {
    return atol(W[n+i+3]);});

  return parlay::tabulate(n, [&] (size_t i) {
    auto degree = edges[i+1] - edges[i];
    return parlay::tabulate(degree, [&] (size_t j) { return edges[j]; });});
}

int main(int argc, char** argv) {
  auto infile = deepsea::cmdline::parse_or_default_string("infile", "graph");
  auto G = readGraphFromFile((char*)infile.c_str());
  size_t result;
  pbbsBench::launch([&] {
    result = bfs(G, 0, false);
  });
  std::cout << "result " << result << std::endl;
  return 0;
}
