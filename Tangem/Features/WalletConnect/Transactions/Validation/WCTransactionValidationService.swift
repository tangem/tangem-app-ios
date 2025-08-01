//
//  WCTransactionValidationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol WCTransactionValidationService {
    func validateCustomFee(_ customFee: Fee?, against highestNetworkFee: Fee?) -> [WCNotificationEvent]

    func validateCustomFeeTooHigh(_ customFee: Fee?, against highestNetworkFee: Fee?) -> [WCNotificationEvent]

    func validateCustomFeeTooLow(_ customFee: Fee?, against highestNetworkFee: Fee?) -> [WCNotificationEvent]

    func validateBalance(transactionAmount: Decimal, fee: Fee?, availableBalance: Decimal) -> [WCNotificationEvent]

    func validateSimulationResult(_ state: TransactionSimulationState) -> [WCNotificationEvent]

    func validateNetworkStatus(isReachable: Bool) -> [WCNotificationEvent]
}

final class CommonWCTransactionValidationService: WCTransactionValidationService {
    func validateCustomFee(_ customFee: Fee?, against highestNetworkFee: Fee?) -> [WCNotificationEvent] {
        guard let customFee else { return [] }

        var events: [WCNotificationEvent] = []

        if let highestNetworkFee {
            let magnitudeTrigger: Decimal = 5

            if customFee.amount.value > highestNetworkFee.amount.value * magnitudeTrigger {
                let highFeeOrder = customFee.amount.value / highestNetworkFee.amount.value
                let orderOfMagnitude = highFeeOrder.intValue(roundingMode: .plain)
                events.append(.customFeeTooHigh(orderOfMagnitude: orderOfMagnitude))
            }

            if customFee.amount.value < highestNetworkFee.amount.value * 0.5 {
                events.append(.customFeeTooLow)
            }
        }

        return events
    }

    func validateCustomFeeTooHigh(_ customFee: Fee?, against highestNetworkFee: Fee?) -> [WCNotificationEvent] {
        guard let customFee, let highestNetworkFee else { return [] }

        let magnitudeTrigger: Decimal = 5

        if customFee.amount.value > highestNetworkFee.amount.value * magnitudeTrigger {
            let highFeeOrder = customFee.amount.value / highestNetworkFee.amount.value
            let orderOfMagnitude = highFeeOrder.intValue(roundingMode: .plain)
            return [.customFeeTooHigh(orderOfMagnitude: orderOfMagnitude)]
        }

        return []
    }

    func validateCustomFeeTooLow(_ customFee: Fee?, against highestNetworkFee: Fee?) -> [WCNotificationEvent] {
        guard let customFee, let highestNetworkFee else { return [] }

        if customFee.amount.value < highestNetworkFee.amount.value * 0.5 {
            return [.customFeeTooLow]
        }

        return []
    }

    func validateBalance(transactionAmount: Decimal, fee: Fee?, availableBalance: Decimal) -> [WCNotificationEvent] {
        let feeAmount = fee?.amount.value ?? 0
        let totalRequired = transactionAmount + feeAmount

        if totalRequired > availableBalance {
            if transactionAmount > availableBalance {
                return [.insufficientBalance]
            } else {
                return [.insufficientBalanceForFee]
            }
        }

        return []
    }

    func validateSimulationResult(_ state: TransactionSimulationState) -> [WCNotificationEvent] {
        guard case .simulationSucceeded(let result) = state else {
            return []
        }

        switch result.validationStatus {
        case .warning:
            return [.suspiciousTransaction(description: result.validationDescription)]
        case .malicious:
            return [.maliciousTransaction(description: result.validationDescription)]
        default:
            return []
        }
    }

    func validateNetworkStatus(isReachable: Bool) -> [WCNotificationEvent] {
        return isReachable ? [] : [.networkFeeUnreachable]
    }
}
