//
//  NEARProtocolConfig.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct NEARProtocolConfig {
    struct Costs {
        /// `transfer_cost.send_not_sir` + `action_receipt_creation_config.send_not_sir` or
        /// `transfer_cost.send_sir` + `action_receipt_creation_config.send_sir`.
        let cumulativeBasicSendCost: Decimal

        /// `transfer_cost.execution` + `action_receipt_creation_config.execution`.
        let cumulativeBasicExecutionCost: Decimal

        /// `create_account_cost.send_not_sir` + `add_key_cost.full_access_cost.send_not_sir` or
        /// `create_account_cost.send_sir` + `add_key_cost.full_access_cost.send_sir`.
        let cumulativeAdditionalSendCost: Decimal

        /// `create_account_cost.execution` + `add_key_cost.full_access_cost.execution`.
        let cumulativeAdditionalExecutionCost: Decimal
    }

    let senderIsReceiver: Costs
    let senderIsNotReceiver: Costs
    let storageAmountPerByte: Decimal

    /// `min_gas_purchase_price`. The price the sender is charged for the gas of the receipts
    /// the transaction creates; the unburnt part of it comes back as a refund.
    let minGasPurchasePrice: Decimal

    /// `pessimistic_gas_price_inflation_ratio`. The price of a receipt is raised by this ratio
    /// once per block the receipt has to travel before it is executed.
    let pessimisticGasPriceInflationRatio: Decimal
}

// MARK: - Convenience extensions

extension NEARProtocolConfig {
    init(from result: NEARNetworkResult.ProtocolConfig) {
        let transactionCosts = result.runtimeConfig.transactionCosts
        let transferCost = transactionCosts.actionCreationConfig.transferCost
        let createAccountCost = transactionCosts.actionCreationConfig.createAccountCost
        let addKeyCost = transactionCosts.actionCreationConfig.addKeyCost.fullAccessCost
        let actionReceiptCreationCost = transactionCosts.actionReceiptCreationConfig

        let cumulativeBasicExecutionCost = Decimal(transferCost.execution)
            + Decimal(actionReceiptCreationCost.execution)

        let cumulativeAdditionalExecutionCost = Decimal(createAccountCost.execution)
            + Decimal(addKeyCost.execution)

        self.init(
            senderIsReceiver: .init(
                cumulativeBasicSendCost: Decimal(transferCost.sendSir) + Decimal(actionReceiptCreationCost.sendSir),
                cumulativeBasicExecutionCost: cumulativeBasicExecutionCost,
                cumulativeAdditionalSendCost: Decimal(createAccountCost.sendSir) + Decimal(addKeyCost.sendSir),
                cumulativeAdditionalExecutionCost: cumulativeAdditionalExecutionCost
            ),
            senderIsNotReceiver: .init(
                cumulativeBasicSendCost: Decimal(transferCost.sendNotSir) + Decimal(actionReceiptCreationCost.sendNotSir),
                cumulativeBasicExecutionCost: cumulativeBasicExecutionCost,
                cumulativeAdditionalSendCost: Decimal(createAccountCost.sendNotSir) + Decimal(addKeyCost.sendNotSir),
                cumulativeAdditionalExecutionCost: cumulativeAdditionalExecutionCost
            ),
            storageAmountPerByte: Decimal(stringValue: result.runtimeConfig.storageAmountPerByte)
                ?? Self.fallbackProtocolConfig.storageAmountPerByte,
            minGasPurchasePrice: Decimal(stringValue: result.runtimeConfig.minGasPurchasePrice)
                ?? Self.fallbackProtocolConfig.minGasPurchasePrice,
            pessimisticGasPriceInflationRatio: Decimal(transactionCosts.pessimisticGasPriceInflationRatio.numerator)
                / Decimal(transactionCosts.pessimisticGasPriceInflationRatio.denominator)
        )
    }

    /// Values to fall back to when the protocol config can't be fetched. Every one of them is taken from
    /// the `EXPERIMENTAL_protocol_config` response on mainnet, see https://docs.near.org/api/rpc/protocol —
    /// the costs and the storage price in Q4 2023, `min_gas_purchase_price` in July 2026 (protocol version 86).
    static var fallbackProtocolConfig: NEARProtocolConfig {
        NEARProtocolConfig(
            senderIsReceiver: .init(
                cumulativeBasicSendCost: Decimal(115123062500) + Decimal(108059500000),
                cumulativeBasicExecutionCost: Decimal(115123062500) + Decimal(108059500000),
                cumulativeAdditionalSendCost: Decimal(500000000000) + Decimal(101765125000),
                cumulativeAdditionalExecutionCost: Decimal(7200000000000) + Decimal(101765125000)
            ),
            senderIsNotReceiver: .init(
                cumulativeBasicSendCost: Decimal(115123062500) + Decimal(108059500000),
                cumulativeBasicExecutionCost: Decimal(115123062500) + Decimal(108059500000),
                cumulativeAdditionalSendCost: Decimal(500000000000) + Decimal(101765125000),
                cumulativeAdditionalExecutionCost: Decimal(7200000000000) + Decimal(101765125000)
            ),
            storageAmountPerByte: Decimal(stringValue: "10000000000000000000")!,
            minGasPurchasePrice: Decimal(stringValue: "1000000000")!,
            pessimisticGasPriceInflationRatio: 1
        )
    }
}
