module Language.Mimsa.Modules.Uses
  ( extractUses,
  )
where

import qualified Data.Map as M
import Data.Set (Set)
import qualified Data.Set as S
import Language.Mimsa.Types.AST
import Language.Mimsa.Types.Identifiers
import Language.Mimsa.Types.Modules.Module

-- find all uses of external vars, types, infix operators etc
-- used in dependency analysis
-- important - we must not count variables brought in via lambdas or let
-- bindings as those aren't external deps

extractUses :: (Eq ann, Monoid ann) => Expr Name ann -> Set DefIdentifier
extractUses = extractUses_

extractUses_ :: (Eq ann, Monoid ann) => Expr Name ann -> Set DefIdentifier
extractUses_ (MyVar _ a) = S.singleton (DIName a)
extractUses_ (MyAnnotation _ _ expr) =
  extractUses_ expr
extractUses_ (MyIf _ a b c) =
  extractUses_ a <> extractUses_ b <> extractUses_ c
extractUses_ (MyLet _ ident a b) =
  S.difference (extractUses_ a <> extractUses_ b) (extractIdentUses ident)
extractUses_ (MyLetPattern _ pat expr body) =
  let patUses = extractPatternUses pat
   in S.filter (`S.notMember` patUses) (extractUses_ expr <> extractUses_ body)
extractUses_ (MyInfix _ op a b) =
  let infixUses = case op of
        Custom infixOp -> S.singleton (DIInfix infixOp)
        _ -> mempty
   in infixUses
        <> extractUses_ a
        <> extractUses_ b
extractUses_ (MyLambda _ ident a) =
  S.difference (extractUses_ a) (extractIdentUses ident)
extractUses_ (MyApp _ a b) = extractUses_ a <> extractUses_ b
extractUses_ (MyLiteral _ _) = mempty
extractUses_ (MyPair _ a b) = extractUses_ a <> extractUses_ b
extractUses_ (MyRecord _ map') = foldMap extractUses_ map'
extractUses_ (MyRecordAccess _ a _) = extractUses_ a
extractUses_ (MyArray _ map') = foldMap extractUses_ map'
extractUses_ (MyData _ _ a) = extractUses_ a
extractUses_ (MyConstructor _ _) = mempty
extractUses_ (MyTypedHole _ _) = mempty
extractUses_ (MyDefineInfix _ _ a b) = extractUses_ a <> extractUses_ b
extractUses_ (MyPatternMatch _ match patterns) =
  extractUses match <> mconcat patternUses
  where
    patternUses :: [Set DefIdentifier]
    patternUses =
      ( \(pat, expr) ->
          let patUses = extractPatternUses pat
           in S.filter (`S.notMember` patUses) (extractUses expr)
      )
        <$> patterns

extractIdentUses :: Identifier Name ann -> Set DefIdentifier
extractIdentUses (Identifier _ name) = S.singleton (DIName name)

extractPatternUses :: (Eq ann, Monoid ann) => Pattern Name ann -> Set DefIdentifier
extractPatternUses (PWildcard _) = mempty
extractPatternUses (PLit _ _) = mempty
extractPatternUses (PVar _ a) = S.singleton (DIName a)
extractPatternUses (PRecord _ as) =
  mconcat (extractPatternUses <$> M.elems as)
extractPatternUses (PPair _ a b) =
  extractPatternUses a <> extractPatternUses b
extractPatternUses (PConstructor _ _ args) =
  mconcat (extractPatternUses <$> args)
extractPatternUses (PArray _ as spread) =
  mconcat (extractPatternUses <$> as) <> extractSpreadUses spread
extractPatternUses (PString _ a as) =
  extractStringPart a <> extractStringPart as

extractSpreadUses :: Spread Name ann -> Set DefIdentifier
extractSpreadUses NoSpread = mempty
extractSpreadUses (SpreadWildcard _) = mempty
extractSpreadUses (SpreadValue _ a) = S.singleton (DIName a)

extractStringPart :: StringPart Name ann -> Set DefIdentifier
extractStringPart (StrWildcard _) = mempty
extractStringPart (StrValue _ a) = S.singleton (DIName a)