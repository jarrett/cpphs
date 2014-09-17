# Integrating Haskell into a C++ Application

Haskell can integrate with C and C++. There are multiple possible variants on this idea.
Here, we're going to focus on just one scenario: You have a C++ application, and you want
to bolt on some functionality written in Haskell.

This means the `main` function is defined in C++, not Haskell. But it doesn't mean the
integration is a one-way street: We'll be calling Haskell from C++ and C from Haskell.
(We won't try to use C++'s unique features from Haskell. It's much saner to call vanilla
C from Haskell.)

## Overall Strategy

Fortunately, Haskell uses the same kinds of header and object files as C and C++. That
means you can include either language's headers from either language, and link to either
language's object files from either language.

So, our goal is to create the appropriate `.o` and `.h` files, refer to the `.h`s
in our source code, and pass compiler flags so the `.o` files can be linked to.

We're making a C++ app, so we're going to create a `main.cpp` that defines a `main`
function. From the C++ `main` function, we'll call a Haskell function we define. That
Haskell function will, in turn, call a C function we define.

We'll compile the `.hs` sources with GHC. The final compilation phase, which generates
the executable, will be performed by GCC.

I said above we'd only call vanilla C from Haskell. As a general rule, I recommend that if
you need to use a given bit of functionality in both C++ and Haskell, you write it in
either C or Haskell, not C++.

One consequence of that choice is that you'll need to use the `extern "C"` syntax to link
from C++ to C object files. You could consider doing so
[in the C header files](https://stackoverflow.com/questions/3789340/combining-c-and-c-how-does-ifdef-cplusplus-work).

These limitations can be inconvenient, but in my opinion, they're *less* inconvenient than
trying to call C++ from Haskell.

## Naming Conventions

C and C++ are notoriously lacking in agreed-upon naming conventions. To name a few, the
C++ standard library, the C standard library, the OpenGL API, and the Google C++ Style
Guide all follow different rules.

Haskell, on the other hand, has agreed-upon naming conventions. Those conventions happen
to be consistent with at least *some* of the popular C/C++ projects and API. So I'll use
the Haskell conventions as much as possible in my C/C++ code.

You're free to disagree and use a different convention in your own code. The techniques
used here will still work.

## A Starter Haskell File

Make `hello.hs`:

    -- Hello.hs
    module Hello where

    foreign export ccall helloFromHaskell :: IO ()

    helloFromHaskell :: IO ()
    helloFromHaskell = putStrLn "Hello from Haskell"

The interesting part is the `foreign export ccall` declaration. That tells GHC to make the
`helloFromHaskell` declaration available to external C/C++ code.

Compile it:

    ghc -fforce-recomp Hello.hs

(This isn't essential, but we'll be using the `-fforce-recomp` flag every time we call
GHC. It'll be helpful when create a `Makefile`.)

You should now have `Hello.o`, `Hello.hi`, and `Hello_stub.h`. The `.h` and `.o` will
enable us to call our function from C++.

## A Starter C++ File

Make `main.cpp`:

    /* main.cpp */
    #include <iostream>

    int main(int argc, char** argv) {
      std::cout << "Hello from C++\n";
      return 0;
    }

Compile and run it:

    g++ -o main main.cpp
    ./main

## Calling `helloFromHaskell` from C++

Modify `main.cpp`:

    #include <iostream>
    #include "Hello_stub.h"

    int main(int argc, char** argv) {
      hs_init(&argc, &argv);
      std::cout << "Hello from C++\n";
      helloFromHaskell();
      hs_exit();
      return 0;
    }

Notice that we had to initialize and terminate the Haskell runtime. You have to do this
any time you call a Haskell function from C/C++. I recommend doing it once per C/C++
application.

Now we have to compile with extra flags to tell GCC about our local Haskell installation.
This gets verbose, so we're going to start a `Makefile`.

In the `Makefile` below, I'm hard-coding the correct paths for *my system,* where GHC was
installed via Homebrew. Your paths could easily be different, even if you're using
Homebrew. So find the relevant headers and libs on your hard drive and replace the
hard-coded paths as necessary.

    # Makefile
    
    all: main; ./main
    
    main: main.cpp Hello.o; g++ \
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
      -o main main.cpp Hello.o
    
    Hello.o: Hello.hs; ghc -fforce-recomp Hello.hs
    
    .PHONY: clean
    clean: ; rm -rf main && rm -rf *.o && rm -rf *.hi && rm -rf *_stub.h

That's a real mess, and the hard-coded paths aren't portable. This project likely won't
compile on your friend's computer. So there's plenty of room for improvement. For example,
you might use CMake to automatically configure the Haskell header and lib paths for the
local system. But we won't get into that here. I just want to show you the bare minimum
necessary to make something compile.

Run `make`, and you should see the "hello world" output from each language.

## Calling a C Function from Haskell

Let's make a C function to call from Haskell. Create `times_two.h` and `times_two.c`:

    /* times_two.h */
    int timesTwo(int x);
    
    /* times_two.c */
    #include "times_two.h"

    int timesTwo(int x) { return x * 2; }

Add it to your `Makefile` and run `make`:
    
    main: main.cpp times_two.o Hello.o; g++ \
      # Flags omitted...
      -o main main.cpp times_two.o Hello.o
    
    times_two.o: times_two.c; gcc -Wall -c times_two.c

This won't change the functionality of your program, of course. You haven't called
`times_two` yet.

Now let's create a Haskell file that calls `times_two`:
    
    -- TimesSix.hs
    module TimesSix where

    import Foreign.C.Types

    foreign export ccall timesSix :: CInt -> CInt
    foreign import ccall "times_two.h timesTwo" timesTwo :: CInt -> CInt

    timesSix :: CInt -> CInt
    timesSix = timesTwo . (3*)

You've already seen `foreign export` declarations. Now, we've added a `foreign import` to
the mix. Inside the double quotes, we declare the C header where the function is defined
and the C name of the function. After the quotes, we define the name by which the function
will be known in Haskell. We could have aliased the function to a different name if we
wanted to.

Having imported the C function, we can use it, as we do in our definition of `timesSix`.
This shows how we can mix and match C and Haskell functions. We can define a bit of
functionality in C--in this case the `timesTwo` function--and use it in a Haskell
function. We can then export that Haskell function to C as we did above, using the
`foreign export` syntax. Next, we'll see how to call `timesSix` from a C++ file.

## Putting it All Together: A C Func Calls a Haskell Func which Calls a C Func

Modify `main.cpp`:
    
    /* main.cpp */
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

And modify the `Makefile`:

    all: main; ./main
    
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

Run `make`, and you should see your basic arithmetic in action. We've just made a C++ app
that calls a Haskell function that calls a C function.