module TurboHaskell.ValidationSupport.ValidateFieldIO (validateFieldIO) where

import           ClassyPrelude
import           Control.Lens                         hiding ((|>))
import           Data.Generics.Product
import           Data.Generics.Product.Types
import           Data.Proxy
import qualified Data.Text                            as Text
import qualified Data.UUID
import qualified Database.PostgreSQL.Simple           as PG
import qualified Database.PostgreSQL.Simple.ToField as PG
import           TurboHaskell.AuthSupport.Authorization
import           TurboHaskell.ModelSupport
import           TurboHaskell.NameSupport               (humanize)
import           TurboHaskell.ValidationSupport.Types
import           GHC.Generics
import           GHC.Records                          hiding (HasField, getField)
import           GHC.TypeLits                         (KnownSymbol, Symbol)
import Control.Monad.State
import TurboHaskell.HaskellSupport hiding (get)
import TurboHaskell.QueryBuilder

type CustomIOValidation value = value -> IO ValidatorResult

{-# INLINE validateFieldIO #-}
validateFieldIO :: forall field model savedModel idType validationState fieldValue validationStateValue fetchedModel. (
        ?model :: model
        , savedModel ~ NormalizeModel model
        , ?modelContext :: ModelContext
        , PG.FromRow savedModel
        , KnownSymbol field
        , HasField' field model fieldValue
        , HasField field (ValidatorResultFor model) (ValidatorResultFor model) ValidatorResult ValidatorResult
        , KnownSymbol (GetTableName savedModel)
        , PG.ToField fieldValue
        , EqOrIsOperator fieldValue
        , Generic model
    ) => Proxy field -> CustomIOValidation fieldValue ->  StateT (ValidatorResultFor model) IO ()
validateFieldIO fieldProxy customValidation = do
    let value :: fieldValue = getField @field ?model
    result <- liftIO (customValidation value)
    attachValidatorResult fieldProxy result