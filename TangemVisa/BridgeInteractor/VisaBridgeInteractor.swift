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
