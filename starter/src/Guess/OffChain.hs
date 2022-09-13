
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TemplateHaskell #-} --allows you to do type-safe compile-time meta-programming
{-# LANGUAGE NoImplicitPrelude   #-} --PlutusTx prelude has priority over Haskell prelude
{-# LANGUAGE ScopedTypeVariables #-}

{-# LANGUAGE TypeFamilies        #-}
{-# LANGUAGE TypeOperators       #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE TypeApplications    #-}

{-# LANGUAGE RecordWildCards #-}


module Guess.OffChain where

import qualified Control.Monad            as Monad (void)
import qualified Data.Map                 as Map

import qualified Text.Printf              as TextPrintf (printf)
import qualified Prelude                  as P
import qualified Ledger.Constraints       as Constraints
import qualified Plutus.Contract          as PlutusContract
import qualified PlutusTx
import qualified Plutus.V1.Ledger.Scripts as ScriptsLedger
import           Ledger.Ada               as Ada
import qualified Ledger.Tx                as LedgerTx
import qualified Data.Void                as Void (Void)
import           PlutusTx.Prelude
import qualified Data.Text                as DT (Text)

import qualified Guess.OnChain as OnChain
-- 1. Create utxos in the script address

--endpoints (contract monads)

data GiveParams = GiveParams
    {
        giveAmount :: !Integer,
        giveDat :: !Integer

    }

data GrabParams = GrabParams
    {
        grabRedeem :: !Integer
    }

type GiftSchema = 
    PlutusContract.Endpoint "give" GiveParams
    PlutusContract..\/ PlutusContract.Endpoint "grab" GrabParams

give :: PlutusContract.AsContractError e => GiveParams -> PlutusContract.Contract w s e ()
give gp = do
    PlutusContract.logInfo @P.String $ TextPrintf.printf "------------------------------------------------------"
    PlutusContract.logInfo @P.String $ TextPrintf.printf "----------------Give endpoint initialize--------------"
    PlutusContract.logInfo @P.String $ TextPrintf.printf "------------------------------------------------------"
    let d = OnChain.Dat
            { 
                ddata = giveDat gp
            }
        q = giveAmount gp
        tx = Constraints.mustPayToOtherScript OnChain.validatorHash (ScriptsLedger.Datum $ PlutusTx.toBuiltinData d) (lovelaceValueOf q)
        lookups = Constraints.plutusV2OtherScript OnChain.validator
    submittedTx <- PlutusContract.submitTxConstraintsWith @Void.Void lookups tx
    Monad.void $ PlutusContract.awaitTxConfirmed $ LedgerTx.getCardanoTxId submittedTx
    PlutusContract.logInfo @P.String $ TextPrintf.printf "Made transaction of %d adas" q

-- grab :: forall w s e. PlutusContract.AsContractError e => GrabParams -> PlutusContract.Contract w s e ()
-- grab GrabParams{..} = do

--     if redeem == 300
--         then do
            
                
--                 let orefs   = fst <$> Map.toList utxos
--                     lookups = Constraints.unspentOutputs utxos      P.<>
--                             Constraints.plutusV2OtherScript OnChain.validator
--                     tx :: Constraints.TxConstraints Void.Void Void.Void
--                     tx      = mconcat [Constraints.mustSpendScriptOutput oref $ ScriptsLedger.Redeemer $ PlutusTx.toBuiltinData (OnChain.Redeem redeem) | oref <- orefs]
--                 submittedTx <- PlutusContract.submitTxConstraintsWith @Void.Void lookups tx
--                 Monad.void $ PlutusContract.awaitTxConfirmed $ LedgerTx.getCardanoTxId submittedTx
--                 PlutusContract.logInfo @P.String $ "collected gifts"
--         else PlutusContract.logInfo @P.String $ "Wrong guess"

-- getDatum :: (TxOutRef, ChainIndexTxOut) -> OnChain.Dat
-- getDatum (_, o) = do
--     let datHashOrDatum = _ciTxOutScriptDatum o
--     Datum e <- snd datHashOrDatum
--     case (fromBuilinData e :: Maybe OnChain.Dat) of
--         Nothing -> Nothing
--         Just d -> d



-- findUTXO 

-- findUtxosInValidator :: Contract w s Text (Map TxOutRef ChainIndexTxOut)
-- findUtxosInValidator = do
--     utxos <- PlutusContract.utxosAt OnChain.address
--     let xs = [(oref, o) | (oref, o) <- toList utxos]
--     out = findUTXO xs

-- endpoints :: PlutusContract.Contract () GiftSchema DT.Text ()
-- endpoints = PlutusContract.awaitPromise (give' `PlutusContract.select` grab') >> endpoints
--     where 
--         give' = PlutusContract.endpoint @"give" give
--         grab' = PlutusContract.endpoint @"grab" $ grab