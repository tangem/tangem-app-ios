//
//  PolymarketBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemPolymarket

protocol PolymarketBalanceProvider {
    var balancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }

    var totalBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }

    var collateralBalancePublisher: AnyPublisher<TokenBalanceType, Never> { get }

    func refresh(scope: PolymarketBalanceRefreshScope) async
}

final class CommonPolymarketBalanceProvider: PolymarketBalanceProvider {
    private let accountModelsManager: (any AccountModelsManager)?
    private let latestAccountModel: OSAllocatedUnfairLock<(any PolymarketAccountModel)?> = .init(uncheckedState: nil)

    private var accountModelSubscription: AnyCancellable?

    init(userWalletModel: (any UserWalletModel)?) {
        accountModelsManager = userWalletModel?.accountModelsManager

        accountModelSubscription = accountModelPublisher
            .withWeakCaptureOf(self)
            .sink { provider, accountModel in
                provider.latestAccountModel.withLockUnchecked { $0 = accountModel }
            }
    }

    var balancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        accountModelPublisher
            .map { accountModel -> AnyPublisher<FormattedTokenBalanceType, Never> in
                guard let accountModel else {
                    return .just(output: .failure(.empty(BalanceFormatter.defaultEmptyBalanceString)))
                }

                return accountModel.collateralTokenBalanceProvider.balanceTypePublisher
                    .map(CommonPolymarketBalanceProvider.makeFormattedBalance(from:))
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    var totalBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        accountModelPublisher
            .map { accountModel -> AnyPublisher<FormattedTokenBalanceType, Never> in
                guard let accountModel else {
                    return .just(output: .failure(.empty(BalanceFormatter.defaultEmptyBalanceString)))
                }

                return accountModel.collateralTotalBalanceProvider.balanceTypePublisher
                    .map(CommonPolymarketBalanceProvider.makeFormattedBalance(from:))
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    var collateralBalancePublisher: AnyPublisher<TokenBalanceType, Never> {
        accountModelPublisher
            .map { accountModel -> AnyPublisher<TokenBalanceType, Never> in
                guard let accountModel else {
                    return .just(output: .empty(.noData))
                }

                return accountModel.collateralTokenBalanceProvider.balanceTypePublisher
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    func refresh(scope: PolymarketBalanceRefreshScope) async {
        guard let accountModel = latestAccountModel.withLockUnchecked({ $0 }) else {
            PolymarketLogger.error(
                "The balance was refreshed without a Polymarket account",
                error: BalanceProviderError.missingPolymarketAccountModel
            )
            return
        }

        await accountModel.refreshBalance(scope: scope)
    }
}

// MARK: - Errors

extension CommonPolymarketBalanceProvider {
    enum BalanceProviderError: Error {
        case missingPolymarketAccountModel
    }
}

// MARK: - Private implementation

private extension CommonPolymarketBalanceProvider {
    var accountModelPublisher: AnyPublisher<(any PolymarketAccountModel)?, Never> {
        guard let accountModelsManager else {
            return .just(output: nil)
        }

        return AccountModelsAggregator(.polymarket).modelPublisher(from: accountModelsManager)
    }

    static func makeFormattedBalance(from balanceType: TokenBalanceType) -> FormattedTokenBalanceType {
        switch balanceType {
        case .empty:
            return .failure(.empty(BalanceFormatter.defaultEmptyBalanceString))
        case .loading, .failure, .loaded:
            let builder = FormattedTokenBalanceTypeBuilder(format: PolymarketOrderFormatter.money)

            return builder.mapToFormattedTokenBalanceType(type: balanceType)
        }
    }
}
