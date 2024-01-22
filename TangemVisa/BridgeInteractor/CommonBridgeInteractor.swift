//
//  CommonBridgeInteractor.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CommonBridgeInteractor {
    private let evmSmartContractInteractor: EVMSmartContractInteractor
    private let paymentAccount: String
    private let decimalCount: Int

    init(evmSmartContractInteractor: EVMSmartContractInteractor, paymentAccount: String) {
        self.evmSmartContractInteractor = evmSmartContractInteractor
        self.paymentAccount = paymentAccount
        decimalCount = VisaUtilities().visaBlockchain.decimalCount
    }
}

extension CommonBridgeInteractor: VisaBridgeInteractor {
    var accountAddress: String { paymentAccount }

    func loadBalances() async throws -> VisaBalances {
        async let totalBalance = try await evmSmartContractInteractor.ethCall(
            request: VisaSmartContractRequest(
                contractAddress: VisaUtilities().visaToken.contractAddress,
                method: GetTotalBalanceMethod(paymentAccountAddress: paymentAccount)
            )
        ).async()

        async let verifiedBalance = try await evmSmartContractInteractor.ethCall(request: amountRequest(for: .verifiedBalance)).async()
        async let availableAmount = try await evmSmartContractInteractor.ethCall(request: amountRequest(for: .availableForPayment)).async()
        async let blockedAmount = try await evmSmartContractInteractor.ethCall(request: amountRequest(for: .blocked)).async()
        async let debtAmount = try await evmSmartContractInteractor.ethCall(request: amountRequest(for: .debt)).async()
        async let pendingRefundAmount = try await evmSmartContractInteractor.ethCall(request: amountRequest(for: .pendingRefund)).async()

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
        let limitsResponse = try await evmSmartContractInteractor.ethCall(request: amountRequest(for: .limits)).async()
        let parser = LimitsResponseParser()
        let limits = try parser.parseResponse(limitsResponse)
        return limits
    }
}

private extension CommonBridgeInteractor {
    func amountRequest(for amountType: GetAmountMethod.AmountType) -> VisaSmartContractRequest {
        let method = GetAmountMethod(amountType: amountType)
        return VisaSmartContractRequest(contractAddress: paymentAccount, method: method)
    }

    func convertToDecimal(_ value: String) -> Decimal? {
        EthereumUtils.parseEthereumDecimal(value, decimalsCount: decimalCount)
    }
}
