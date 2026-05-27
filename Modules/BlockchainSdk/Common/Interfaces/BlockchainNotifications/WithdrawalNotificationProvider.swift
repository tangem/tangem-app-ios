//
//  WithdrawalNotificationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol WithdrawalNotificationProvider {
    func withdrawalNotification(amount: Amount, fee: Fee) -> WithdrawalNotification?
}

public enum WithdrawalNotification: Hashable {
    case feeIsTooHigh(reduceAmountBy: Amount)
    case cardanoWillBeSendAlongToken(amount: Amount)
    case tronWillBeSendTokenFeeDescription
}
