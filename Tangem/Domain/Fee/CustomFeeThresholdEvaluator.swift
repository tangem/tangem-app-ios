//
//  CustomFeeThresholdEvaluator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

enum CustomFeeWarning: Hashable {
    case tooHigh(orderOfMagnitude: Int)
    case tooLow
}

/// Compares a manually entered custom fee against the suggested fee options.
/// Shared threshold logic used by Send and Swap (transfer mode) notification flows:
/// too low when below the slow option, too high when more than `magnitudeTrigger` times the fast option.
enum CustomFeeThresholdEvaluator {
    private static let magnitudeTrigger: Decimal = 5

    static func evaluate(selectedFee: TokenFee, feeValues: [TokenFee]) -> CustomFeeWarning? {
        guard selectedFee.option == .custom, case .success(let customFee) = selectedFee.value else {
            return nil
        }

        let customValue = customFee.amount.value

        if let fastFee = feeValues.first(where: { $0.option == .fast })?.value.value,
           fastFee.amount.value > 0,
           customValue > fastFee.amount.value * magnitudeTrigger {
            let orderOfMagnitude = (customValue / fastFee.amount.value).intValue(roundingMode: .plain)
            return .tooHigh(orderOfMagnitude: orderOfMagnitude)
        }

        if let slowFee = feeValues.first(where: { $0.option == .slow })?.value.value,
           customValue < slowFee.amount.value {
            return .tooLow
        }

        return nil
    }
}
