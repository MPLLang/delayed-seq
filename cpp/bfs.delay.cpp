#include "cmdline.hpp"
#include "benchmark.hpp"
#include "myGraphIO.h"

int main(int argc, char** argv) {
  auto infile = deepsea::cmdline::parse_or_default_string("infile", "graph");
  auto G = readGraphFromFile((char*)infile.c_str());
  size_t result;
  pbbsBench::launch([&] {
    result = bfs(G, 0, true);
  });
  std::cout << "result " << result << std::endl;
  return 0;
}
