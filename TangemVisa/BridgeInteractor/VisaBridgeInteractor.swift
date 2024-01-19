//
//  VisaBridgeInteractor.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CryptoSwift
import BlockchainSdk

public protocol VisaBridgeInteractor {
    var accountAddress: String { get }
    func loadBalances() async throws -> VisaBalances
    func loadLimits() async throws -> VisaLimits
}

struct DefaultBridgeInteractor {
    private let smartContractInteractor: EVMSmartContractInteractor
    private let paymentAccount: String
    private let decimalCount: Int

    init(smartContractInteractor: EVMSmartContractInteractor, paymentAccount: String) {
        self.smartContractInteractor = smartContractInteractor
        self.paymentAccount = paymentAccount
        decimalCount = VisaUtilities().visaBlockchain.decimalCount
    }
}

extension DefaultBridgeInteractor: VisaBridgeInteractor {
    var accountAddress: String { paymentAccount }

    func loadBalances() async throws -> VisaBalances {
        async let totalBalance = try await smartContractInteractor.ethCall(
            request: VisaSmartContractRequest(
                contractAddress: VisaUtilities().visaToken.contractAddress,
                method: GetTotalBalanceMethod(paymentAccountAddress: paymentAccount)
            )
        ).async()

        async let verifiedBalance = try await smartContractInteractor.ethCall(request: amountRequest(for: .verifiedBalance)).async()
        async let availableAmount = try await smartContractInteractor.ethCall(request: amountRequest(for: .availableForPayment)).async()
        async let blockedAmount = try await smartContractInteractor.ethCall(request: amountRequest(for: .blocked)).async()
        async let debtAmount = try await smartContractInteractor.ethCall(request: amountRequest(for: .debt)).async()
        async let pendingRefundAmount = try await smartContractInteractor.ethCall(request: amountRequest(for: .pendingRefund)).async()

        return try await .init(
            totalBalance: convertToDecimal(totalBalance),
            verifiedBalance: convertToDecimal(verifiedBalance),
            available: convertToDecimal(availableAmount),
            blocked: convertToDecimal(blockedAmount),
            debt: convertToDecimal(debtAmount),
            pendingRefund: convertToDecimal(pendingRefundAmount)
        )
    }

    func loadLimits() async throws -> VisaLimits {
        let limitsResponse = try await smartContractInteractor.ethCall(request: amountRequest(for: .limits)).async()
        let parser = LimitsResponseParser()
        let limits = try parser.parseResponse(limitsResponse)
        return limits
    }
}

private extension DefaultBridgeInteractor {
    func amountRequest(for amountType: GetAmountMethod.AmountType) -> VisaSmartContractRequest {
        let method = GetAmountMethod(amountType: amountType)
        return VisaSmartContractRequest(contractAddress: paymentAccount, method: method)
    }

    func convertToDecimal(_ value: String) -> Decimal? {
        EthereumUtils.parseEthereumDecimal(value, decimalsCount: decimalCount)
    }
}

struct LimitsResponseParser {
    private let responseLenght = 962
    private let singleValueLength = 64
    private let itemsForEachLimit = 7
    private let amountsCount = 5
    private let numberOfLimits = 3

    func parseResponse(_ response: String) throws -> VisaLimits {
        guard response.count == responseLenght else {
            throw ParserError.limitsResponseWrongLength
        }
        var responseWithoutPrefix = response.removeHexPrefix()
        var limitsStrings = split(string: responseWithoutPrefix, by: singleValueLength * itemsForEachLimit)

        guard limitsStrings.count == numberOfLimits else {
            throw ParserError.limitsResponseWrongLength
        }

        let oldLimit = try parseLimit(limitsStrings.removeFirst())
        let newLimit = try parseLimit(limitsStrings.removeFirst())
        let timeIntervalWhenLimitsChange = EthereumUtils.parseEthereumDecimal(limitsStrings.removeFirst(), decimalsCount: 0)?.doubleValue ?? 0

        return VisaLimits(
            oldLimit: oldLimit,
            newLimit: newLimit,
            changeDate: Date(timeIntervalSince1970: timeIntervalWhenLimitsChange)
        )
    }

    private func split(string: String, by length: Int) -> [String] {
        var startIndex = string.startIndex
        var results = [Substring]()

        while startIndex < string.endIndex {
            let endIndex = string.index(startIndex, offsetBy: length, limitedBy: string.endIndex) ?? string.endIndex
            results.append(string[startIndex ..< endIndex])
            startIndex = endIndex
        }

        return results.map { String($0) }
    }

    private func parseLimit(_ limit: String) throws -> VisaLimit {
        guard limit.count == itemsForEachLimit * singleValueLength else {
            throw ParserError.limitWrongLength
        }

        var limitItems = split(string: limit, by: singleValueLength)

        let remainingLimitSeconds = EthereumUtils.parseEthereumDecimal(limitItems.removeLast(), decimalsCount: 0)
        let timeIntervalWhenLimitEnds = EthereumUtils.parseEthereumDecimal(limitItems.removeLast(), decimalsCount: 0)
        let dueDate = Date(timeIntervalSince1970: timeIntervalWhenLimitEnds?.doubleValue ?? 0)

        let decimalCount = VisaUtilities().visaBlockchain.decimalCount
        var values = limitItems.map { EthereumUtils.parseEthereumDecimal($0, decimalsCount: decimalCount) }

        guard values.count == amountsCount else {
            throw ParserError.failedToParseLimitAmount
        }

        return VisaLimit(
            dueDate: dueDate,
            remainingTimeSeconds: remainingLimitSeconds?.doubleValue ?? 0,
            singleTransaction: values.removeFirst(),
            otpLimit: values.removeFirst(),
            spentOTPAmount: values.removeFirst(),
            noOTPLimit: values.removeFirst(),
            spentNoOTPAmount: values.removeFirst()
        )
    }
}

extension Decimal {
    var doubleValue: Double {
        decimalNumber.doubleValue
    }

    var decimalNumber: NSDecimalNumber {
        self as NSDecimalNumber
    }
}

public enum ParserError: Error {
    case addressResponseDoesntContainAddress
    case noValidAddress
    case limitsResponseWrongLength
    case limitWrongLength
    case failedToParseLimitAmount
}
