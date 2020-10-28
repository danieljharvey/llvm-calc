{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Language.Mimsa.Types.AST.Operator
  ( Operator (..),
  )
where

import qualified Data.Aeson as JSON
import GHC.Generics (Generic)
import Language.Mimsa.Printer

-------

data Operator = Equals | Add | Subtract
  deriving (Eq, Ord, Show, Generic, JSON.FromJSON, JSON.ToJSON)

instance Printer Operator where
  prettyDoc Equals = "=="
  prettyDoc Add = "+"
  prettyDoc Subtract = "-"
