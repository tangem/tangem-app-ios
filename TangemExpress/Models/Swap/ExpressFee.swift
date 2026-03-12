//
//  ExpressFee.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressFee {
    public let option: Option
    public let fee: BSDKFee

    public init(option: Option, fee: BSDKFee) {
        self.option = option
        self.fee = fee
    }
}

public extension ExpressFee {
    enum Option: Hashable {
        case market
        case fast
    }
}
