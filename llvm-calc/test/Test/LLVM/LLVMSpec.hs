{-# LANGUAGE OverloadedStrings #-}

module Test.LLVM.LLVMSpec (spec) where

import qualified Calc.Compile.RunLLVM as Run
import Calc.Compile.ToLLVM
import Calc.Parser
import Data.Foldable (traverse_)
import Data.Text (Text)
import qualified LLVM.AST as LLVM
import Test.Hspec

-- run the code, get the output, die
run :: LLVM.Module -> IO Text
run = fmap Run.rrResult . Run.run

testCompileIR :: (Text, Text) -> Spec
testCompileIR (input, result) = it (show input) $ do
  case parseExprAndFormatError input of
    Left e -> error (show e)
    Right expr -> do
      resp <- run (toLLVM expr)
      resp `shouldBe` result

spec :: Spec
spec = do
  describe "LLVMSpec" $ do
    let testVals =
          [ ("42", "42"),
            ("(1 + 1)", "2"),
            ("1 + 2 + 3 + 4 + 5 + 6", "21"),
            ("6 * 6", "36"),
            ("100 - 1", "99")
          ]

    describe "From expressions" $ do
      traverse_ testCompileIR testVals
