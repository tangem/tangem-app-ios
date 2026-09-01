//
//  PolymarketOnboardingProgress.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro
import TangemPolymarket

typealias PolymarketOnboardingContinuation = AsyncStream<PolymarketOnboardingProgress>.Continuation

@CaseFlagable
enum PolymarketOnboardingProgress {
    case deriving
    case awaitingSignature
    case working(PolymarketDepositWalletStatus)
    case ready
    case handedOff(PolymarketDepositWalletStatus)
    case failed(PolymarketOnboardingError)
}

@CaseFlagable
enum PolymarketOnboardingError: Error {
    case derivation(PolymarketDerivationError)
    case signing(PolymarketSigningError)
    case wallet(PolymarketWalletError)
    case addressMismatch
    case depositWalletDerivation
    case walletIdTaken
    case credentials
    case deploymentFailed
    case approvalsFailed
    case unknown
}

extension PolymarketOnboardingError {
    var isCancellation: Bool {
        switch self {
        case .derivation(.cancelled), .signing(.cancelled), .wallet(.cancelled): true
        default: false
        }
    }

    var isRetryable: Bool {
        switch self {
        case .walletIdTaken, .addressMismatch, .depositWalletDerivation:
            false
        case .derivation(let error):
            switch error {
            case .missingWallet, .derivationUnsupported, .addressCreationFailed: false
            case .cancelled, .cardFailed, .keyNotDerived, .unknown: true
            }
        case .signing(let error):
            switch error {
            case .notDerived, .addressCreationFailed: false
            case .cancelled, .cardFailed, .unknown: true
            }
        case .wallet(let error):
            switch error {
            case .badRequest, .unauthorized: false
            case .conflict, .relayerRejected, .upstreamUnavailable, .cancelled, .other: true
            }
        case .credentials, .deploymentFailed, .approvalsFailed, .unknown:
            true
        }
    }
}
