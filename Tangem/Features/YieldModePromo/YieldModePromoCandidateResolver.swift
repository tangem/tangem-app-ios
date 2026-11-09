//
//  YieldModePromoCandidateResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct YieldModePromoCandidateResolver {
    func resolve(positions: [YieldModePromoPosition], markets: [YieldModuleMarketInfo]) -> Resolution {
        let derivedPositions = positions.filter { $0.balance != .missingDerivation }

        guard !derivedPositions.contains(where: { $0.yieldState == .active }) else {
            return .noEligibleToken
        }

        let matchedPositions = derivedPositions.compactMap { position -> (market: Market, position: YieldModePromoPosition)? in
            Self.activeMarket(for: position, in: markets).map { ($0, position) }
        }

        guard !matchedPositions.isEmpty else {
            return .noEligibleToken
        }

        let isYieldStateLoading = derivedPositions.contains { $0.balance != .failed && $0.yieldState == .loading }
        let isMatchedPositionLoading = matchedPositions.contains { Self.isLoading($0.position) }

        guard !isYieldStateLoading, !isMatchedPositionLoading else {
            return .waiting
        }

        guard !derivedPositions.contains(where: { $0.balance == .failed || $0.yieldState == .failed }) else {
            return .dataNotReady
        }

        let notActivePositions = matchedPositions.filter { $0.position.yieldState == .notActive }

        let candidates = Dictionary(grouping: notActivePositions, by: \.market).compactMap { market, entries -> Candidate? in
            let positions = entries.map(\.position)

            guard market.apy > 0, Self.loadedSum(of: positions.map(\.balance)) > 0 else {
                return nil
            }

            return Candidate(
                chainId: market.chainId,
                contractAddress: market.contractAddress,
                tokenSymbol: positions[0].tokenSymbol,
                blockchainName: positions[0].blockchainName,
                apy: market.apy,
                fiatBalance: Self.loadedSum(of: positions.map(\.fiatBalance))
            )
        }

        guard let candidate = candidates.min(by: Self.isPreferred) else {
            return .noEligibleToken
        }

        return .candidate(candidate)
    }

    private static func activeMarket(for position: YieldModePromoPosition, in markets: [YieldModuleMarketInfo]) -> Market? {
        guard let chainId = position.chainId, let contractAddress = position.contractAddress else {
            return nil
        }

        return markets
            .first { $0.isActive && $0.chainId == chainId && $0.tokenContractAddress.caseInsensitiveEquals(to: contractAddress) }
            .map { Market(chainId: chainId, contractAddress: $0.tokenContractAddress, apy: $0.effectiveApy) }
    }

    private static func isLoading(_ position: YieldModePromoPosition) -> Bool {
        guard position.balance != .failed else {
            return false
        }

        return position.balance == .loading || position.fiatBalance == .loading || position.yieldState == .awaitingMarkets
    }

    private static func loadedSum(of balances: [YieldModePromoPosition.Balance]) -> Decimal {
        balances.reduce(Decimal.zero) { total, balance in
            guard case .loaded(let value) = balance else {
                return total
            }

            return total + value
        }
    }

    private static func isPreferred(_ lhs: Candidate, over rhs: Candidate) -> Bool {
        if lhs.apy != rhs.apy {
            return lhs.apy > rhs.apy
        }

        if lhs.fiatBalance != rhs.fiatBalance {
            return lhs.fiatBalance > rhs.fiatBalance
        }

        if lhs.chainId != rhs.chainId {
            return lhs.chainId < rhs.chainId
        }

        return lhs.contractAddress.caseInsensitiveSmaller(than: rhs.contractAddress)
    }
}

// MARK: - Types

extension YieldModePromoCandidateResolver {
    enum Resolution: Equatable {
        case waiting
        case noEligibleToken
        case dataNotReady
        case candidate(Candidate)
    }

    struct Candidate: Equatable {
        let chainId: Int
        let contractAddress: String
        let tokenSymbol: String
        let blockchainName: String
        let apy: Decimal
        let fiatBalance: Decimal
    }

    private struct Market: Hashable {
        let chainId: Int
        let contractAddress: String
        let apy: Decimal
    }
}
