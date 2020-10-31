{-# LANGUAGE OverloadedStrings #-}

module Language.Mimsa.Types.Error.TypeError
  ( TypeError (..),
    getErrorPos,
  )
where

import Data.Foldable (fold)
import Data.Map (Map)
import qualified Data.Map as M
import Data.Maybe (fromMaybe)
import Data.Set (Set)
import qualified Data.Set as S
import qualified Data.Text as T
import Data.Text.Prettyprint.Doc
  ( (<+>),
    Doc,
    Pretty (pretty),
    vsep,
  )
import Language.Mimsa.Printer
import Language.Mimsa.Types.AST
import Language.Mimsa.Types.Environment (Environment (getDataTypes))
import Language.Mimsa.Types.Identifiers
  ( Name,
    TyCon,
    Variable (..),
    mkName,
    renderName,
  )
import Language.Mimsa.Types.MonoType
import Language.Mimsa.Types.Swaps (Swaps)
import Text.Megaparsec

data TypeError
  = UnknownTypeError
  | FailsOccursCheck Swaps Variable MonoType
  | UnificationError MonoType MonoType
  | VariableNotInEnv Swaps Annotation Variable (Set Variable)
  | MissingRecordMember Annotation Name (Set Name)
  | MissingRecordTypeMember Annotation Name (Map Name MonoType)
  | MissingBuiltIn Annotation Variable
  | NoFunctionEquality MonoType MonoType
  | CannotMatchRecord Environment Annotation MonoType
  | CaseMatchExpectedPair Annotation MonoType
  | CannotCaseMatchOnType (Expr Variable Annotation)
  | TypeConstructorNotInScope Environment Annotation TyCon
  | TypeVariableNotInDataType TyCon Name [Name]
  | ConflictingConstructors Annotation TyCon
  | CannotApplyToType TyCon
  | DuplicateTypeDeclaration TyCon
  | IncompletePatternMatch Annotation [TyCon]
  | MixedUpPatterns [TyCon]
  deriving (Eq, Ord, Show)

------

instance Semigroup TypeError where
  a <> _ = a

instance Monoid TypeError where
  mempty = UnknownTypeError

instance Printer TypeError where
  prettyDoc = vsep . renderTypeError

instance ShowErrorComponent TypeError where
  showErrorComponent = T.unpack . prettyPrint
  errorComponentLen typeErr = let (_, len) = getErrorPos typeErr in len

type Start = Int

type Length = Int

fromAnnotation :: Annotation -> (Start, Length)
fromAnnotation (Location a b) = (a, b - a)
fromAnnotation _ = (0, 0)

getErrorPos :: TypeError -> (Start, Length)
getErrorPos (UnificationError a b) =
  fromAnnotation (getAnnotationForType a <> getAnnotationForType b)
getErrorPos (MissingRecordMember ann _ _) = fromAnnotation ann
getErrorPos (MissingRecordTypeMember ann _ _) = fromAnnotation ann
getErrorPos (VariableNotInEnv _ ann _ _) = fromAnnotation ann
getErrorPos (TypeConstructorNotInScope _ ann _) = fromAnnotation ann
getErrorPos (ConflictingConstructors ann _) = fromAnnotation ann
getErrorPos (MissingBuiltIn ann _) = fromAnnotation ann
getErrorPos (IncompletePatternMatch ann _) = fromAnnotation ann
getErrorPos (CaseMatchExpectedPair ann _) =
  fromAnnotation ann
getErrorPos (CannotCaseMatchOnType expr) =
  fromAnnotation (getAnnotation expr)
getErrorPos (CannotMatchRecord _ ann _) = fromAnnotation ann
getErrorPos _ = (0, 0)

------

showKeys :: (p -> Doc ann) -> Map p a -> [Doc ann]
showKeys renderP record = renderP <$> M.keys record

showSet :: (a -> Doc ann) -> Set a -> [Doc ann]
showSet renderA set = renderA <$> S.toList set

showMap :: (k -> Doc ann) -> (a -> Doc ann) -> Map k a -> [Doc ann]
showMap renderK renderA map' =
  (\(k, a) -> renderK k <+> ":" <+> renderA a)
    <$> M.toList map'

------

withSwap :: Swaps -> Variable -> Name
withSwap _ (BuiltIn n) = n
withSwap _ (BuiltInActual n _) = n
withSwap _ (NamedVar n) = n
withSwap swaps (NumberedVar i) =
  fromMaybe
    (mkName "unknownvar")
    (M.lookup (NumberedVar i) swaps)

-----

renderTypeError :: TypeError -> [Doc ann]
renderTypeError UnknownTypeError =
  ["Unknown type error"]
renderTypeError (FailsOccursCheck swaps var mt) =
  [ prettyDoc var <+> "appears inside" <+> prettyDoc mt <+> ".",
    "Swaps:"
  ]
    <> showMap prettyDoc prettyDoc swaps
renderTypeError (UnificationError a b) =
  [ "Unification error",
    "Cannot match" <+> prettyDoc a <+> "and" <+> prettyDoc b
  ]
renderTypeError (CannotCaseMatchOnType ty) =
  ["Cannot case match on type", prettyDoc ty]
renderTypeError (VariableNotInEnv swaps _ name members) =
  ["Variable" <+> renderName (withSwap swaps name) <+> " not in scope."]
    <> showSet prettyDoc members
renderTypeError (MissingRecordMember _ name members) =
  [ "Cannot find" <+> prettyDoc name <> ".",
    "The following are available:"
  ]
    <> showSet renderName members
renderTypeError (MissingRecordTypeMember _ name types) =
  [ "Cannot find" <+> renderName name <> ".",
    "The following types are available:"
  ]
    <> showKeys renderName types
renderTypeError (MissingBuiltIn _ var) =
  ["Cannot find built-in function" <+> prettyDoc var]
renderTypeError (CannotMatchRecord env _ mt) =
  [ "Cannot match type" <+> prettyDoc mt <+> "to record.",
    "The following are available:",
    pretty (show env)
  ]
renderTypeError (CaseMatchExpectedPair _ mt) =
  ["Expected pair but got" <+> prettyDoc mt]
renderTypeError (TypeConstructorNotInScope env _ constructor) =
  [ "Type constructor for" <+> prettyDoc constructor
      <+> "not found in scope.",
    "The following are available:"
  ]
    <> printDataTypes env
renderTypeError (ConflictingConstructors _ constructor) =
  ["Multiple constructors found matching" <+> prettyDoc constructor]
renderTypeError (CannotApplyToType constructor) =
  ["Cannot apply value to" <+> prettyDoc constructor]
renderTypeError (DuplicateTypeDeclaration constructor) =
  ["Cannot redeclare existing type name" <+> prettyDoc constructor]
renderTypeError (TypeVariableNotInDataType constructor name as) =
  [ "Type variable" <+> renderName name
      <+> "could not be in found in type vars for"
      <+> prettyDoc constructor,
    "The following type variables were found:"
  ]
    <> (renderName <$> as)
renderTypeError (IncompletePatternMatch _ names) =
  [ "Incomplete pattern match.",
    "Missing constructors:"
  ]
    <> (prettyDoc <$> names)
renderTypeError (MixedUpPatterns names) =
  [ "Mixed up patterns in same match.",
    "Constructors:"
  ]
    <> (prettyDoc <$> names)
renderTypeError (NoFunctionEquality a b) =
  ["Cannot use == on functions", prettyDoc a, prettyDoc b]

printDataTypes :: Environment -> [Doc ann]
printDataTypes env = mconcat $ snd <$> M.toList (printDt <$> getDataTypes env)
  where
    printDt :: DataType -> [Doc ann]
    printDt (DataType tyName tyVars constructors) =
      [prettyDoc tyName] <> printTyVars tyVars
        <> zipWith (<>) (":" : repeat "|") (printCons <$> M.toList constructors)
    printTyVars as = renderName <$> as
    printCons (consName, args) =
      fold
        ( [ prettyDoc
              consName
          ]
            <> (prettyDoc <$> args)
        )