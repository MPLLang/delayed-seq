#pragma once

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
    auto degree = offsets[i+1] - offsets[i];
    return parlay::tabulate(degree, [&] (size_t j) { return edges[offsets[i]+j]; });});
}
