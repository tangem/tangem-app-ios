//
//  TangemPayOfframpPreSignatureVerifier.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemPay

struct TangemPayOfframpPreSignatureVerifier {
    private let fiatItem: FiatItem

    init(fiatItem: FiatItem) {
        self.fiatItem = fiatItem
    }

    func verify(_ preSignature: TangemPayWithdrawPreSignature, against expectation: Expectation) throws(Error) {
        let typedData = preSignature.structuredData

        guard let domainChainId = typedData.domain[DomainKey.chainId].flatMap(Self.chainId(from:)),
              let messageAsset = typedData.message[MessageKey.asset]?.stringValue,
              domainChainId == expectation.chainId,
              messageAsset.caseInsensitiveCompare(expectation.tokenContractAddress) == .orderedSame
        else {
            throw .networkMismatch
        }

        let decimalCount = TangemPayUtilities.tokenDecimalCount(chainId: expectation.chainId)
        let expectedAmount = fiatItem.convertFromCents(value: expectation.amountInCents) * pow(10, decimalCount)

        guard let messageAmount = typedData.message[MessageKey.amount].flatMap(Self.amount(from:)),
              messageAmount == expectedAmount
        else {
            throw .amountMismatch
        }

        guard preSignature.isHashConsistent else {
            throw .hashMismatch
        }
    }
}

// MARK: - Expectation

extension TangemPayOfframpPreSignatureVerifier {
    struct Expectation: Equatable {
        let amountInCents: Decimal
        let chainId: Int
        let tokenContractAddress: String
    }
}

extension TangemPayOfframpPreSignatureVerifier.Expectation {
    init?(request: TangemPayPlaceOrderRequest) {
        guard request.data.type == TangemPayOrderType.bankOfframpRain.rawValue,
              let amountInCents = request.data.amountInCents,
              let chainId = request.data.chainId,
              let tokenContractAddress = request.data.tokenContractAddress
        else {
            return nil
        }

        self.init(
            amountInCents: Decimal(amountInCents),
            chainId: chainId,
            tokenContractAddress: tokenContractAddress
        )
    }
}

// MARK: - Error

extension TangemPayOfframpPreSignatureVerifier {
    enum Error: LocalizedError {
        case amountMismatch
        case networkMismatch
        case hashMismatch
    }
}

// MARK: - Parsing

private extension TangemPayOfframpPreSignatureVerifier {
    enum MessageKey {
        static let asset = "asset"
        static let amount = "amount"
    }

    enum DomainKey {
        static let chainId = "chainId"
    }

    static func chainId(from json: JSON) -> Int? {
        json.intValue ?? json.stringValue.flatMap { Int($0) }
    }

    static func amount(from json: JSON) -> Decimal? {
        json.intValue.map { Decimal($0) } ?? json.stringValue.flatMap { Decimal(string: $0) }
    }
}
