{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings #-}

module Language.Mimsa.Types
  ( ExprHash (..),
    StoreEnv (..),
    Bindings (..),
    Store (..),
    StoreExpression (..),
    module Language.Mimsa.Types.Name,
    module Language.Mimsa.Types.AST,
  )
where

import qualified Data.Aeson as JSON
import qualified Data.Map as M
import GHC.Generics
import Language.Mimsa.Types.AST
import Language.Mimsa.Types.Name

------------

newtype ExprHash = ExprHash Int
  deriving (Eq, Ord, Show)
  deriving newtype (JSON.FromJSON, JSON.ToJSON)

-------

-- our environment contains whichever hash/expr pairs we have flapping about
-- and a list of mappings of names to those pieces
data StoreEnv
  = StoreEnv
      { store :: Store,
        bindings :: Bindings
      }

instance Semigroup StoreEnv where
  StoreEnv a a' <> StoreEnv b b' = StoreEnv (a <> b) (a' <> b')

instance Monoid StoreEnv where
  mempty = StoreEnv mempty mempty

--------

-- store is where we keep the big map of hashes to expresions
newtype Store = Store {getStore :: M.Map ExprHash Expr}
  deriving newtype (Eq, Ord, Show, Semigroup, Monoid)

-- a list of names to hashes
newtype Bindings = Bindings {getBindings :: M.Map Name ExprHash}
  deriving newtype (Eq, Ord, Show, Semigroup, Monoid, JSON.FromJSON, JSON.ToJSON)

-- a storeExpression contains the AST Expr
-- and a map of names to hashes with further functions inside
-- not sure whether to store the builtins we need here too?
data StoreExpression
  = StoreExpression
      { storeBindings :: Bindings,
        storeExpression :: Expr
      }
  deriving (Eq, Ord, Show, Generic)
  deriving (JSON.ToJSON, JSON.FromJSON)
