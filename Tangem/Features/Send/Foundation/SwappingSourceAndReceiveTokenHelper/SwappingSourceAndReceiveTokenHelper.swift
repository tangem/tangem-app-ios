//
//  SwappingSourceAndReceiveTokenHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemMacro

struct SwappingSourceAndReceiveTokenHelper {
    func canBeSwappedPublisher(
        source: LoadingResult<any SendSourceToken, any Error>,
        receive: LoadingResult<any SendReceiveToken, any Error>
    ) -> AnyPublisher<Availability, Never> {
        switch (source, receive) {
        case (.loading, _), (_, .loading):
            return .just(output: .unavailable)

        case (_, .success(let receive as SendSwapableToken)):
            return receive.sendingRestrictionsProvider.sendingRestrictionsPublisher
                .map { restrictions -> Availability in
                    guard let restrictions, restrictions.preventsSwapFromToken else {
                        return .available
                    }

                    return .restricted(restrictions)
                }
                .eraseToAnyPublisher()

        case (_, .success), (_, .failure):
            return .just(output: .available)
        }
    }

    func canBeSwapped(
        source: LoadingResult<any SendSourceToken, any Error>,
        receive: LoadingResult<any SendReceiveToken, any Error>
    ) async -> Availability {
        do {
            return try await canBeSwappedPublisher(source: source, receive: receive).first().async()
        } catch {
            return .unavailable
        }
    }
}

// MARK: - Availability

extension SwappingSourceAndReceiveTokenHelper {
    @CaseFlagable
    enum Availability {
        case available
        case unavailable
        case restricted(SendingRestrictions)
    }
}

// MARK: - SendingRestrictions+

private extension SendingRestrictions {
    var preventsSwapFromToken: Bool {
        switch self {
        case .cantSignLongTransactions, .blockchainUnreachable, .blockchainLoading, .hasOnlyCachedBalance:
            true
        case .zeroWalletBalance, .hasPendingWithdrawOrder, .hasPendingTransaction, .zeroFeeCurrencyBalance, .oldCard, .noAccount:
            false
        }
    }
}
