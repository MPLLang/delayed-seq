#include <parlay/sequence.h>
#include <parlay/primitives.h>

#include "cmdline.hpp"
#include "benchmarkShared.hpp"

#include "pbbsbench/common/geometry.h"

#include "bestcut.h"

int main(int argc, char** argv) {

  size_t block_size =
    std::max((size_t)2, (size_t)deepsea::cmdline::parse_or_default_long("block-size", 1000000));
  
  auto events = generateInput(200000000);
  range r(0, 200000000), r1(0, 200000000), r2(0, 200000000);
  
  cutInfo R;
  pbbsBench::launch([&] {
    R = bestCutStreamOfBlocks(block_size, events, r, r1, r2);
  });
}
