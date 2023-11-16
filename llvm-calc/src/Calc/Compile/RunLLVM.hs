{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Calc.Compile.RunLLVM (run, RunResult (..)) where

import Data.ByteString.Char8 as BS
import Control.Exception (bracket)
import Data.FileEmbed
import Data.String.Conversions
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import qualified Data.Text.IO as T
import qualified LLVM.AST as LLVM
import LLVM.Pretty
import System.CPUTime
import System.Directory
import System.IO
import System.Posix.Temp
import System.Process
import qualified Text.Printf as Printf
import qualified LLVM.Module as LLVM

-- these are saved in a file that is included in compilation
cRuntime :: Text
cRuntime =
  T.decodeUtf8 $(makeRelativeToProject "static/runtime.c" >>= embedFile)

data RunResult = RunResult
  { rrResult :: Text,
    rrComptime :: Text,
    rrRuntime :: Text
  }

-- run the code, get the output, die
run :: LLVM.Module -> IO () -- RunResult
run mod = withContext $ \ctx -> do
  llvm <- LLLVM.withModuleFromAST ctx mod LLVM.moduleLLVMAssembly
  BS.putStrLn llvm
  --pure (RunResult result compTime runTime)
