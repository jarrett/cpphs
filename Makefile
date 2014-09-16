all: main; ./main

# Compiling and linking with Haskell requires some headers and libraries. Specifically,
# those that come with GHC. (If your Haskell code uses a Cabal package, there will be even
# more dependencies. The flags below just give you the minimal Haskell dependencies.)
# 
# In this case, we're compiling against the Homebrew GHC. Haskell Platform also comes with
# essentially the same files.
# 
# This needs to be less brittle. We're hard-coding system paths and library versions.
# Instead, we should search for the latest version of the required library. Consider
# using CMake, pkg-config, or ghc --print-libdir.
main: main.cpp times_two.o Hello.o TimesSix.o; g++ \
  -liconv \
  -I/usr/local/Cellar/ghc/7.6.3/lib/ghc-7.6.3/include \
  -L/usr/local/Cellar/ghc/7.6.3/lib/ghc-7.6.3 \
  -lHSrts \
  -L/usr/local/Cellar/ghc/7.6.3/lib/ghc-7.6.3/base-4.6.0.1 \
  -lHSbase-4.6.0.1 \
  -L/usr/local/Cellar/ghc/7.6.3/lib/ghc-7.6.3/ghc-prim-0.3.0.0 \
  -lHSghc-prim-0.3.0.0 \
  -L/usr/local/Cellar/ghc/7.6.3/lib/ghc-7.6.3/integer-gmp-0.5.0.0 \
  -lHSinteger-gmp-0.5.0.0 \
  -lHSghc-prim-0.3.0.0 \
  -fno-stack-protector \
  -Wall \
  -o main main.cpp times_two.o Hello.o TimesSix.o

times_two.o: times_two.c; gcc -Wall -c times_two.c

Hello.o: Hello.hs; ghc -fforce-recomp Hello.hs

TimesSix.o: TimesSix.hs; ghc -fforce-recomp TimesSix.hs

.PHONY: clean
clean: ; rm -rf main && rm -rf *.o && rm -rf *.hi && rm -rf *_stub.h