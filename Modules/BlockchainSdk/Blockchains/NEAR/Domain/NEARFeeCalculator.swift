//
//  NEARFeeCalculator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// The fee covers what the network locks on the account of the sender while it validates the transaction, which is
/// more than what it eventually burns: the gas of the receipts is bought upfront, at a price of its own, and the
/// unburnt part comes back as a refund.
struct NEARFeeCalculator {
    private let protocolConfig: NEARProtocolConfig
    private let gasPrice: Decimal
    private let decimalValue: Decimal

    init(protocolConfig: NEARProtocolConfig, gasPrice: Decimal, decimalValue: Decimal) {
        self.protocolConfig = protocolConfig
        self.gasPrice = gasPrice
        self.decimalValue = decimalValue
    }

    func calculateFee(source: String, destination: String) -> Decimal {
        let senderIsReceiver = source.caseInsensitiveCompare(destination) == .orderedSame
        let costs = senderIsReceiver ? protocolConfig.senderIsReceiver : protocolConfig.senderIsNotReceiver

        // A receipt to another account is executed in the next block and its price is raised for that hop,
        // while a receipt to the account of the sender is executed in the same block and travels none
        let inflation = senderIsReceiver ? 1 : protocolConfig.pessimisticGasPriceInflationRatio
        let executionGasPrice = (max(gasPrice, protocolConfig.minGasPurchasePrice) * inflation)
            .rounded(scale: 0, roundingMode: .up)

        var sendGas = costs.cumulativeBasicSendCost
        var executionGas = costs.cumulativeBasicExecutionCost

        // An account with an implicit ID has to be created by [REDACTED_AUTHOR]
        // see https://nomicon.io/RuntimeSpec/Fees/ for details
        if NEARAddressUtil.isImplicitAccount(accountId: destination) {
            sendGas += costs.cumulativeAdditionalSendCost
            executionGas += costs.cumulativeAdditionalExecutionCost
        }

        let totalCost = sendGas * gasPrice + executionGas * executionGasPrice

        return totalCost / decimalValue
    }
}
