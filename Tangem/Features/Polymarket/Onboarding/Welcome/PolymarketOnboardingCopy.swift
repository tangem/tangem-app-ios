//
//  PolymarketOnboardingCopy.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPolymarket

enum PolymarketOnboardingCopy {}

// MARK: - Stages

extension PolymarketOnboardingCopy {
    // [REDACTED_TODO_COMMENT]
    static func stage(for runState: PolymarketWelcomeViewModel.RunState, status: PolymarketDepositWalletStatus?) -> String? {
        switch runState {
        case .idle:
            return nil
        case .deriving:
            return "Preparing your keys"
        case .awaitingSignature:
            return "Waiting for your confirmation"
        case .working:
            return workingStage(for: status)
        }
    }

    private static func workingStage(for status: PolymarketDepositWalletStatus?) -> String {
        // [REDACTED_TODO_COMMENT]
        switch status {
        case .notCreated, .deploymentInProgress, .none:
            return "Creating your prediction account"
        case .deployed, .approvalsInProgress:
            return "Enabling trading"
        case .readyToTrade:
            return "Finishing up"
        case .deploymentFailed, .approvalsFailed, .unknown:
            return "Setting up your prediction account"
        }
    }
}

// MARK: - Failures

extension PolymarketOnboardingCopy {
    // [REDACTED_TODO_COMMENT]
    static func failure(for error: PolymarketOnboardingError) -> String {
        switch error {
        case .regionUnknown:
            return "We couldn't check whether predictions are available in your region."
        case .walletIdTaken:
            return "This wallet already has a prediction account created on another device."
        case .addressMismatch:
            return "The prediction account we got back doesn't belong to this wallet."
        case .depositWalletDerivation:
            return "We couldn't work out the address of your prediction account."
        case .credentials:
            return "We couldn't sign you in to Polymarket."
        case .deploymentFailed:
            return "We couldn't create your prediction account."
        case .approvalsFailed:
            return "Your prediction account was created, but trading couldn't be enabled for it."
        case .derivation(let error):
            return derivationFailure(error)
        case .signing(let error):
            return signingFailure(error)
        case .wallet(let error):
            return walletFailure(error)
        case .regionBlocked, .unknown:
            return Localization.commonUnknownError
        }
    }

    private static func derivationFailure(_ error: PolymarketDerivationError) -> String {
        // [REDACTED_TODO_COMMENT]
        switch error {
        case .derivationUnsupported, .missingWallet:
            return "This wallet can't be used for predictions."
        case .cardFailed:
            return "The card didn't answer. Hold it to the phone again."
        case .keyNotDerived, .addressCreationFailed, .cancelled, .unknown:
            return Localization.commonUnknownError
        }
    }

    private static func signingFailure(_ error: PolymarketSigningError) -> String {
        // [REDACTED_TODO_COMMENT]
        switch error {
        case .notDerived:
            return "This wallet can't be used for predictions."
        case .cardFailed:
            return "The card didn't answer. Hold it to the phone again."
        case .addressCreationFailed, .cancelled, .unknown:
            return Localization.commonUnknownError
        }
    }

    private static func walletFailure(_ error: PolymarketWalletError) -> String {
        // [REDACTED_TODO_COMMENT]
        switch error {
        case .unauthorized, .badRequest:
            return "Polymarket turned the request down."
        case .upstreamUnavailable:
            return "Polymarket isn't answering right now."
        case .relayerRejected:
            return "The transaction that creates your prediction account was rejected."
        case .conflict:
            return "This wallet already has a prediction account created on another device."
        case .cancelled, .other:
            return Localization.commonUnknownError
        }
    }
}

// MARK: - LocalizedError

extension PolymarketOnboardingError: @retroactive LocalizedError {
    public var errorDescription: String? {
        PolymarketOnboardingCopy.failure(for: self)
    }
}
