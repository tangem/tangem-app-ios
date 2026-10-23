//
//  JointOperationRefusal.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum JointOperationRefusal: Hashable {
    case unsupportedChain
    case nonceMismatch
    case invalidBaseGas
    case gasPriceTooLow
    case gasPriceTooHigh
    case gasTokenNotAllowed
    case invalidRefundReceiver
    case invalidSafeOperation
    case invalidSafeAddress
    case unknown(String)
}
