module TimesSix where

import Foreign.C.Types

foreign export ccall timesSix :: CInt -> CInt
foreign import ccall "times_two.h times_two" timesTwo :: CInt -> CInt

timesSix :: CInt -> CInt
timesSix = timesTwo . (3*)