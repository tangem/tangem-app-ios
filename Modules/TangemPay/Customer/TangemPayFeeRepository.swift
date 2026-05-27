//
//  TangemPayFeeRepository.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public actor TangemPayFeeRepository {
    private var storage: [TangemPayFeeType: TangemPayFeeResponse] = [:]

    public init() {}

    public func getFee(for type: TangemPayFeeType) -> TangemPayFeeResponse? {
        storage[type]
    }

    public func setFee(_ fee: TangemPayFeeResponse, for type: TangemPayFeeType) {
        storage[type] = fee
    }
}
