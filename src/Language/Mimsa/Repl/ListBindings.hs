{-# LANGUAGE OverloadedStrings #-}

module Language.Mimsa.Repl.ListBindings
  ( doListBindings,
  )
where

import Data.Foldable (traverse_)
import Data.Text (Text)
import Language.Mimsa.Actions
import Language.Mimsa.Printer
import Language.Mimsa.Project
  ( getCurrentBindings,
    getCurrentTypeBindings,
  )
import Language.Mimsa.Repl.Types
import Language.Mimsa.Types.AST
import Language.Mimsa.Types.Project
import Language.Mimsa.Types.ResolvedExpression
import Language.Mimsa.Types.Store

doListBindings :: Project Annotation -> Text -> ReplM Annotation ()
doListBindings env input = do
  let showBind (name, StoreExpression expr _ _) =
        case getTypecheckedStoreExpression input env expr of
          Right (ResolvedExpression type' _ _ _ _) ->
            replPrint (prettyPrint name <> " :: " <> prettyPrint type')
          _ -> pure ()
  traverse_
    showBind
    ( getExprPairs
        (store env)
        (getCurrentBindings $ bindings env)
    )
  let showType dt = replPrint (prettyPrint dt)
  traverse_
    showType
    ( getTypesFromStore
        (store env)
        (getCurrentTypeBindings $ typeBindings env)
    )
