//
//  OnrampTransactionStatus.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public enum OnrampTransactionStatus: String, Codable {
    case unknown
    case created
    case expired
    case waitingForPayment = "waiting-for-payment"
    case paymentProcessing = "payment-processing"
    case verifying
    case failed
    case paid
    case sending
    case refunding = "refund-in-progress"
    case refunded
    case finished
    case paused
}
