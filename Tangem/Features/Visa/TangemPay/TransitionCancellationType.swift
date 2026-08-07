//
//  TransitionCancellationType.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TransitionCancellationType {
    case plainCancel(orderId: String)
    case cancelAndFallbackToBasic(orderId: String)

    var orderId: String {
        switch self {
        case .plainCancel(let orderId), .cancelAndFallbackToBasic(let orderId):
            return orderId
        }
    }
}
