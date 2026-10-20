//
//  PolymarketDerivationErrorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
import TangemSdk

@Suite
struct PolymarketDerivationErrorTests {
    @Test(arguments: CardFailure.allCases)
    func cardFailuresKeepTheirRetryability(failure: CardFailure) {
        #expect(PolymarketDerivationError(derivationFailure: failure.sdkError) == failure.expectedError)
    }

    @Test
    func aDismissedUnlockIsACancellation() {
        #expect(PolymarketDerivationError(derivationFailure: CancellationError()) == .cancelled)
    }

    @Test
    func aFailureThatIsNotTheCardIsNotBlamedOnTheCard() {
        struct NetworkishError: Error {}

        #expect(PolymarketDerivationError(derivationFailure: NetworkishError()) == .unknown)
    }
}

// MARK: - Scenarios

extension PolymarketDerivationErrorTests {
    enum CardFailure: CaseIterable, Sendable {
        case userCancelled
        case walletNotFound
        case otherCardError

        var sdkError: TangemSdkError {
            switch self {
            case .userCancelled: .userCancelled
            case .walletNotFound: .walletNotFound
            case .otherCardError: .cardError
            }
        }

        var expectedError: PolymarketDerivationError {
            switch self {
            case .userCancelled: .cancelled
            case .walletNotFound: .missingWallet
            case .otherCardError: .cardFailed
            }
        }
    }
}
