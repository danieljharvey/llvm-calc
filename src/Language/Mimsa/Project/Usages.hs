module Language.Mimsa.Project.Usages where

import Data.Bifunctor (first)
import qualified Data.Map as M
import Data.Set (Set)
import qualified Data.Set as S
import Language.Mimsa.Project.Persistence (getCurrentBindings)
import Language.Mimsa.Store.ResolvedDeps (resolveDeps)
import Language.Mimsa.Types.Bindings
import Language.Mimsa.Types.ExprHash
import Language.Mimsa.Types.Name
import Language.Mimsa.Types.Project
import Language.Mimsa.Types.ResolvedDeps
import Language.Mimsa.Types.Store
import Language.Mimsa.Types.StoreExpression
import Language.Mimsa.Types.Usage

findUsages :: Project -> ExprHash -> Either UsageError (Set Usage)
findUsages (Project store' bindings') exprHash' =
  findUsages_ store' (getCurrentBindings bindings') exprHash'

resolveDepsOrUsageError :: Store -> Bindings -> Either UsageError ResolvedDeps
resolveDepsOrUsageError store' bindings' =
  first (CouldNotResolveDeps) (resolveDeps store' bindings')

findUsages_ :: Store -> Bindings -> ExprHash -> Either UsageError (Set Usage)
findUsages_ store' bindings' exprHash = do
  (ResolvedDeps resolvedDeps) <- resolveDepsOrUsageError store' bindings'
  let directDeps = mconcat $ addUsageIfMatching exprHash <$> (M.toList resolvedDeps)
  inDirectDeps <-
    traverse
      ( \(name', (hash, storeExpr)) -> do
          subDeps <- findUsages_ store' (storeBindings storeExpr) exprHash
          if S.null subDeps
            then pure mempty
            else pure $ S.singleton (Transient name' hash)
      )
      (M.toList resolvedDeps)
  pure $ directDeps <> (mconcat inDirectDeps)

addUsageIfMatching :: ExprHash -> (Name, (ExprHash, StoreExpression)) -> Set Usage
addUsageIfMatching exprHash (name, (hash, storeExpr')) =
  let matchingNames = getMatches exprHash (storeBindings storeExpr')
   in if S.null matchingNames
        then mempty
        else S.singleton (Direct name hash)

-- list of names in some Bindings that use our hash
getMatches :: ExprHash -> Bindings -> Set Name
getMatches exprHash (Bindings bindings') =
  S.fromList . M.keys . M.filter (\a -> a == exprHash) $ bindings'