#include <iostream>
#include "Hello_stub.h"
#include "TimesSix_stub.h"
#include "times_two.h"

int main(int argc, char** argv) {
  hs_init(&argc, &argv);
  std::cout << "Hello from C++\n";
  helloFromHaskell();
  std::cout << "2 x 6 = " << timesSix(2) << "\n";
  hs_exit();
  return 0;
}