{-# LANGUAGE OverloadedStrings #-}

module Language.Mimsa.Parser.Identifier
  ( identifierParser,
  )
where

import Data.Functor (($>))
import Language.Mimsa.Parser.Helpers
import Language.Mimsa.Parser.Identifiers
import Language.Mimsa.Parser.MonoType
import Language.Mimsa.Parser.Types
import Language.Mimsa.Types.AST
import Language.Mimsa.Types.Identifiers
import Text.Megaparsec
import Text.Megaparsec.Char

----

identifierParser :: Parser (Identifier Name Annotation)
identifierParser =
  try (inBrackets annotatedIdentifierParser)
    <|> plainIdentifierParser

annotatedIdentifierParser :: Parser (Identifier Name Annotation)
annotatedIdentifierParser =
  withLocation (\ann (mt, name) -> AnnotatedIdentifier (mt $> ann) name) $ do
    name <- nameParser
    _ <- withOptionalSpace (string ":")
    mt <- monoTypeParser
    pure (mt, name)

plainIdentifierParser :: Parser (Identifier Name Annotation)
plainIdentifierParser =
  withLocation
    Identifier
    nameParser