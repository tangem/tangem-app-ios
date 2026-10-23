//
//  Collectibles+UniversalError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

// `Subsystems`:
// `000` - CollectiblesSendError
// `001` - CollectiblesOnboardingError
// `002` - CollectiblesVaultProgram.ProgramError
// `003` - CommonCollectiblesChainReader.ReadError
// `004` - CommonCollectiblesSessionKeyWalletStore.KeyError
// `005` - CollectiblesPreparedTransaction.ParsingError
// `006` - CollectiblesBuybackTransactionVerifier.VerificationError
// `007` - CollectiblesPurchaseTransactionDispatcher.ValidationError
// `008` - CollectiblesManager.PurchaseError
// `009` to `016` - app-side errors, see `Collectibles+UniversalError.swift` in the app target
// `017` - CollectiblesProgramRejection

extension CollectiblesSendError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .transactionExpired: 114000000
        case .rejected(let error): (error as? any UniversalError)?.errorCode ?? 114000001
        case .outcomeUnknown: 114000002
        }
    }
}

extension CollectiblesOnboardingError: UniversalError {
    var errorCode: Int {
        switch self {
        case .coldKeyNotDerived: 114001000
        case .stateUnresolved: 114001001
        case .stepDidNotAdvance: 114001002
        }
    }
}

extension CollectiblesVaultProgram.ProgramError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .invalidProgramId: 114002000
        case .invalidPublicKey: 114002001
        case .invalidAccountData: 114002002
        case .invalidCaps: 114002003
        case .impossibleVaultAccount: 114002004
        case .invalidPurchase: 114002005
        }
    }
}

extension CommonCollectiblesChainReader.ReadError: UniversalError {
    var errorCode: Int {
        switch self {
        case .configMissing: 114003000
        }
    }
}

extension CommonCollectiblesSessionKeyWalletStore.KeyError: UniversalError {
    var errorCode: Int {
        switch self {
        case .keyMissing: 114004000
        case .masterKeyUnavailable: 114004001
        case .signingFailed: 114004002
        }
    }
}

extension CollectiblesPreparedTransaction.ParsingError: UniversalError {
    var errorCode: Int {
        switch self {
        case .invalidLength: 114005000
        case .unsupportedMessageVersion: 114005001
        case .addressTableLookups: 114005002
        case .trailingBytes: 114005003
        case .missingSignatures: 114005004
        case .signatureSlotsMismatch: 114005005
        case .malformedHeader: 114005006
        case .indexOutsideAccountKeys: 114005007
        }
    }
}

extension CollectiblesBuybackTransactionVerifier.VerificationError: UniversalError {
    var errorCode: Int {
        switch self {
        case .ownerNotSigner: 114006000
        case .ownerWritable: 114006001
        case .cosignerSignatureMissing: 114006002
        case .unexpectedInstruction: 114006003
        case .repeatedInstruction: 114006004
        case .missingInstruction: 114006005
        case .foreignAsset: 114006006
        case .foreignPayout: 114006007
        case .payoutBelowAgreedPrice: 114006008
        }
    }
}

extension CollectiblesPurchaseTransactionDispatcher.ValidationError: UniversalError {
    var errorCode: Int {
        switch self {
        case .mintMismatch: 114007000
        case .amountMismatch: 114007001
        case .feeAboveConfirmed: 114007002
        case .feeOutsideCorridor: 114007003
        case .exceedsLimits: 114007004
        }
    }
}

extension CollectiblesManager.PurchaseError: UniversalError {
    var errorCode: Int {
        switch self {
        case .vaultNotReady: 114008000
        case .conflictingPurchase: 114008001
        }
    }
}

extension CollectiblesProgramRejection: UniversalError {
    public var errorCode: Int {
        switch self {
        case .instructionFallbackNotFound: 114017000
        case .accountDidNotDeserialize: 114017001
        case .accountOwnedByWrongProgram: 114017002
        case .invalidProgramId: 114017003
        case .accountNotInitialized: 114017004
        case .paused: 114017005
        case .zeroAmount: 114017006
        case .invalidMemo: 114017007
        case .invalidFeeBps: 114017008
        case .invalidCaps: 114017009
        case .exceedsPerSpinCap: 114017010
        case .exceedsDailyCap: 114017011
        case .mathOverflow: 114017012
        case .notAnNft: 114017013
        case .buybackDelegationDisabled: 114017014
        case .buybackSlotOccupied: 114017015
        case .noLiveBuyback: 114017016
        case .wrongBuybackToken: 114017017
        case .buybackStillActive: 114017018
        case .vaultNotClean: 114017019
        case .tokenAccountNotEmpty: 114017020
        case .delegateStillSet: 114017021
        case .insufficientSol: 114017022
        case .unauthorized: 114017023
        case .cannotSweepUsdc: 114017024
        case .excessLamports: 114017025
        case .unsupportedMint: 114017026
        case .feeBelowMinimum: 114017027
        case .feeAboveMaximum: 114017028
        case .invalidConfigAccount: 114017029
        }
    }
}
