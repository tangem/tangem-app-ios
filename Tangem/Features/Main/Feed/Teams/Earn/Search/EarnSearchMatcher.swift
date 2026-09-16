//
//  EarnSearchMatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct EarnSearchMatcher {
    func match(_ tokens: [EarnTokenModel], query: String) -> [EarnTokenModel] {
        let query = query.trimmed().lowercased()

        guard query.isNotEmpty else {
            return []
        }

        return tokens
            .compactMap { token in relevance(of: token, for: query).map { RankedToken(relevance: $0, token: token) } }
            .sorted()
            .map(\.token)
    }
}

// MARK: - Ranking

private extension EarnSearchMatcher {
    func relevance(of token: EarnTokenModel, for query: String) -> RankedToken.Relevance? {
        let symbol = token.symbol.lowercased()
        let name = token.name.lowercased()

        if symbol == query {
            return .exactSymbol
        }

        if symbol.hasPrefix(query) {
            return .symbolPrefix
        }

        if name.hasPrefix(query) {
            return .namePrefix
        }

        if symbol.contains(query) || name.contains(query) {
            return .substring
        }

        return nil
    }
}

// MARK: - RankedToken

private struct RankedToken: Comparable {
    let relevance: Relevance
    let token: EarnTokenModel

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.relevance != rhs.relevance {
            return lhs.relevance < rhs.relevance
        }

        if lhs.token.rateValue != rhs.token.rateValue {
            return lhs.token.rateValue > rhs.token.rateValue
        }

        switch lhs.token.name.caseInsensitiveCompare(rhs.token.name) {
        case .orderedAscending: return true
        case .orderedDescending: return false
        case .orderedSame: return lhs.token.networkName < rhs.token.networkName
        }
    }

    enum Relevance: Int, Comparable {
        case exactSymbol
        case symbolPrefix
        case namePrefix
        case substring

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
