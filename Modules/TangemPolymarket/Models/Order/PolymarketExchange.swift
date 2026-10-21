//
//  PolymarketExchange.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketExchange {
    public static let depositWalletSignatureType = 3

    public static let emptyWord = "0x" + String(repeating: "0", count: 64)

    static let domainName = "Polymarket CTF Exchange"
    static let chainId = UInt64(PolymarketChain.polygonId)

    public static func domain(for quote: PolymarketOrderQuote, isNegRisk: Bool) throws(PolymarketExchangeDomainError) -> PolymarketExchangeDomain {
        guard let expected = PolymarketExchangeDomain.expected(version: quote.version, isNegRisk: isNegRisk) else {
            throw .unsupportedVersion(quote.version)
        }

        guard
            let exchange = quote.exchange,
            exchange.caseInsensitiveCompare(expected.address) == .orderedSame,
            quote.signingDomainVersion == expected.version
        else {
            throw .mismatch(exchange: quote.exchange, signingDomainVersion: quote.signingDomainVersion)
        }

        return expected
    }
}

// MARK: - Domain

public struct PolymarketExchangeDomain: Hashable, Sendable {
    public let address: String
    public let version: String

    static let ctfExchange = PolymarketExchangeDomain(
        address: PolymarketApprovalContracts.ctfExchange,
        version: Constants.v1DomainVersion
    )

    static let negRiskCtfExchange = PolymarketExchangeDomain(
        address: PolymarketApprovalContracts.negRiskCtfExchange,
        version: Constants.v1DomainVersion
    )

    static let exchangeV3 = PolymarketExchangeDomain(
        address: PolymarketApprovalContracts.exchangeV3,
        version: Constants.v2DomainVersion
    )

    static func expected(version: PolymarketMarketVersion, isNegRisk: Bool) -> PolymarketExchangeDomain? {
        switch version {
        case .v1: isNegRisk ? .negRiskCtfExchange : .ctfExchange
        case .v2: .exchangeV3
        case .unknown: nil
        }
    }
}

private extension PolymarketExchangeDomain {
    enum Constants {
        static let v1DomainVersion = "2"
        static let v2DomainVersion = "3"
    }
}

// MARK: - Error

public enum PolymarketExchangeDomainError: Error, Hashable {
    case unsupportedVersion(PolymarketMarketVersion)
    case mismatch(exchange: String?, signingDomainVersion: String?)
}
