//
//  PortfolioReviewMapper+HoldingBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PortfolioReviewMapper {
    enum HoldingBuilder {
        typealias TokenHolding = PortfolioReviewAggregator.TokenHolding
        typealias Availability = PortfolioReviewAggregator.Availability

        static func build(_ item: TokenItemType) -> TokenHolding {
            switch item {
            case .default(let walletModel):
                makeDerivedHolding(walletModel)
            case .withoutDerivation(let tokenItem):
                makeAddresslessHolding(tokenItem)
            }
        }
    }
}

// MARK: - Holdings

private extension PortfolioReviewMapper.HoldingBuilder {
    /// Nothing is derived yet, so there's no balance to fetch and no rate to apply — only the token's identity is known.
    static func makeAddresslessHolding(_ tokenItem: TokenItem) -> TokenHolding {
        TokenHolding(
            groupKey: tokenItem.groupKey,
            networkKey: tokenItem.networkId,
            networkName: tokenItem.networkName,
            symbol: tokenItem.currencySymbol,
            tokenItem: tokenItem,
            // Only the "not in Tangem's list" half is knowable here; the custom-derivation half needs a derived path.
            isCustom: tokenItem.id == nil,
            amountInCrypto: nil,
            amountInFiat: nil,
            availability: .noAddress
        )
    }

    static func makeDerivedHolding(_ walletModel: any WalletModel) -> TokenHolding {
        let tokenItem = walletModel.tokenItem
        // Total (available + staked), matching the main screen — available-only shrinks staked assets into "Other".
        let fiatBalance = walletModel.fiatTotalTokenBalanceProvider.balanceType
        let availability = availability(for: fiatBalance)

        return TokenHolding(
            groupKey: tokenItem.groupKey,
            networkKey: tokenItem.networkId,
            networkName: tokenItem.networkName,
            symbol: tokenItem.currencySymbol,
            tokenItem: tokenItem,
            isCustom: walletModel.isCustom,
            // Crypto shows whenever known (incl. no-rate custom); fiat only when there's a value.
            amountInCrypto: availability.showsCrypto ? walletModel.totalTokenBalanceProvider.balanceType.value : nil,
            amountInFiat: fiatAmount(for: fiatBalance, availability: availability),
            availability: availability
        )
    }

    /// Row fiat. A `.noAccount` balance (e.g. an unfunded XRP wallet) is a confirmed-empty zero, so it's
    /// dropped like any zero holding; other states carry their value or stay `nil` while unresolved.
    static func fiatAmount(for balance: TokenBalanceType, availability: Availability) -> Decimal? {
        if case .empty(.noAccount) = balance {
            return 0
        }
        return availability.showsValue ? balance.value : nil
    }

    /// Balance status → row availability: `.some`/`.none` cached value splits refreshing from nothing-yet, and could-not-refresh from unreachable.
    static func availability(for balance: TokenBalanceType) -> Availability {
        switch balance {
        case .loading(.some): return .cache
        case .loading(.none): return .loading
        case .failure(.some): return .onlyCache
        case .failure(.none): return .unreachable
        case .empty(.noData): return .loading
        case .empty(.noDerivation): return .noAddress
        case .empty(.custom): return .noRate
        case .empty, .loaded: return .content
        }
    }
}

// MARK: - TokenItem+GroupKey

private extension TokenItem {
    /// Same asset across accounts/derivations → one key: `currencyId`, or network + lowercased contract for customs.
    var groupKey: String {
        switch self {
        case .token(let token, _):
            return token.id ?? "\(networkId)_\(token.contractAddress.lowercased())"
        case .blockchain(let network):
            return network.blockchain.currencyId
        }
    }
}
