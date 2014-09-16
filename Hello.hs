module Hello where

foreign export ccall helloFromHaskell :: IO ()

helloFromHaskell :: IO ()
helloFromHaskell = putStrLn "Hello from Haskell"