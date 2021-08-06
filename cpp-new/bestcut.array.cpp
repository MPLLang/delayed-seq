#include <parlay/sequence.h>
#include <parlay/primitives.h>

#include "cmdline.hpp"
#include "benchmarkShared.hpp"

#include "pbbsbench/common/geometry.h"

#include "bestcut.h"

int main(int argc, char** argv) {
  
  auto events = generateInput(200000000);
  range r(0, 200000000), r1(0, 200000000), r2(0, 200000000);
  
  cutInfo R;
  pbbsBench::launch([&] {
    R = bestCutNoDelay(events, r, r1, r2);
  });
}
