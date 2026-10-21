//
//  CollectiblesProgramRejectionTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemCollectibles

/// The raw values are the on-chain program's own error codes — an accidental renumbering here silently
/// misclassifies whatever `broadcast(coldKey:instructions:)` maps a rejection into.
@Suite("CollectiblesProgramRejection")
struct CollectiblesProgramRejectionTests {
    @Test("Raw values match the on-chain error codes")
    func rawValuesMatchTheOnChainErrorCodes() {
        #expect(CollectiblesProgramRejection.instructionFallbackNotFound.rawValue == 101)
        #expect(CollectiblesProgramRejection.accountDidNotDeserialize.rawValue == 3003)
        #expect(CollectiblesProgramRejection.accountOwnedByWrongProgram.rawValue == 3007)
        #expect(CollectiblesProgramRejection.invalidProgramId.rawValue == 3008)
        #expect(CollectiblesProgramRejection.accountNotInitialized.rawValue == 3012)
        #expect(CollectiblesProgramRejection.paused.rawValue == 6000)
        #expect(CollectiblesProgramRejection.zeroAmount.rawValue == 6001)
        #expect(CollectiblesProgramRejection.invalidMemo.rawValue == 6002)
        #expect(CollectiblesProgramRejection.invalidFeeBps.rawValue == 6003)
        #expect(CollectiblesProgramRejection.invalidCaps.rawValue == 6004)
        #expect(CollectiblesProgramRejection.exceedsPerSpinCap.rawValue == 6005)
        #expect(CollectiblesProgramRejection.exceedsDailyCap.rawValue == 6006)
        #expect(CollectiblesProgramRejection.mathOverflow.rawValue == 6007)
        #expect(CollectiblesProgramRejection.notAnNft.rawValue == 6008)
        #expect(CollectiblesProgramRejection.buybackDelegationDisabled.rawValue == 6009)
        #expect(CollectiblesProgramRejection.buybackSlotOccupied.rawValue == 6010)
        #expect(CollectiblesProgramRejection.noLiveBuyback.rawValue == 6011)
        #expect(CollectiblesProgramRejection.wrongBuybackToken.rawValue == 6012)
        #expect(CollectiblesProgramRejection.buybackStillActive.rawValue == 6013)
        #expect(CollectiblesProgramRejection.vaultNotClean.rawValue == 6014)
        #expect(CollectiblesProgramRejection.tokenAccountNotEmpty.rawValue == 6015)
        #expect(CollectiblesProgramRejection.delegateStillSet.rawValue == 6016)
        #expect(CollectiblesProgramRejection.insufficientSol.rawValue == 6017)
        #expect(CollectiblesProgramRejection.unauthorized.rawValue == 6018)
        #expect(CollectiblesProgramRejection.cannotSweepUsdc.rawValue == 6019)
        #expect(CollectiblesProgramRejection.excessLamports.rawValue == 6020)
        #expect(CollectiblesProgramRejection.unsupportedMint.rawValue == 6021)
        #expect(CollectiblesProgramRejection.feeBelowMinimum.rawValue == 6022)
        #expect(CollectiblesProgramRejection.feeAboveMaximum.rawValue == 6023)
        #expect(CollectiblesProgramRejection.invalidConfigAccount.rawValue == 6024)
    }

    @Test("Decodes from the program's raw error code")
    func decodesFromTheProgramsRawErrorCode() {
        #expect(CollectiblesProgramRejection(rawValue: 6018) == .unauthorized)
        #expect(CollectiblesProgramRejection(rawValue: 999_999) == nil)
    }
}
