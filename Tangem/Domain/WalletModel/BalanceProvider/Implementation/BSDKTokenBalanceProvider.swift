//
//  BSDKTokenBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

typealias BSDKTokenBalance = Decimal

protocol BSDKTokenBalanceProviderInput: AnyObject {
    func balance(for tokenItem: TokenItem) -> BSDKTokenBalance?
    func balancePublisher(for tokenItem: TokenItem) -> AnyPublisher<BSDKTokenBalance?, Never>
}

class BSDKTokenBalanceProvider {
    private weak var input: BSDKTokenBalanceProviderInput?

    private let tokenItem: TokenItem
    private let balanceFormatter = BalanceFormatter()

    init(
        input: BSDKTokenBalanceProviderInput,
        tokenItem: TokenItem
    ) {
        self.input = input
        self.tokenItem = tokenItem
    }
}

// MARK: - TokenBalanceProvider

extension BSDKTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        guard let input else {
            assertionFailure("BSDKTokenBalanceProviderInput not found")
            return .empty(.noData)
        }

        return mapToTokenBalance(state: input.balance(for: tokenItem))
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        guard let input else {
            assertionFailure("BSDKTokenBalanceProviderInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.balancePublisher(for: tokenItem)
            .withWeakCaptureOf(self)
            .map { $0.mapToTokenBalance(state: $1) }
            .eraseToAnyPublisher()
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        mapToFormattedTokenBalanceType(type: balanceType)
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceTypePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToFormattedTokenBalanceType(type: $1) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension BSDKTokenBalanceProvider {
    func mapToTokenBalance(state: BSDKTokenBalance?) -> TokenBalanceType {
        switch state {
        case .none:
            return .empty(.noData)
        case .some(let balance):
            return .loaded(balance)
        }
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let currencyCode = tokenItem.currencySymbol
        let builder = FormattedTokenBalanceTypeBuilder(format: { [balanceFormatter] value in
            balanceFormatter.formatCryptoBalance(value, currencyCode: currencyCode)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
