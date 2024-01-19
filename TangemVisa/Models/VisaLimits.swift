//
//  VisaLimits.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaLimits {
    public let oldLimit: VisaLimit
    public let newLimit: VisaLimit
    public let changeDate: Date
}

public struct VisaLimit {
    public let dueDate: Date
    public let remainingTimeSeconds: Double
    public let singleTransaction: Decimal?
    public let otpLimit: Decimal?
    public let spentOTPAmount: Decimal?
    public let noOTPLimit: Decimal?
    public let spentNoOTPAmount: Decimal?

    public var remainingOTPAmount: Decimal? {
        guard let otpLimit, let spentOTPAmount else {
            return nil
        }

        return otpLimit - spentOTPAmount
    }

    public var remainingNoOTPAmount: Decimal? {
        guard let noOTPLimit, let spentNoOTPAmount else {
            return nil
        }

        return noOTPLimit - spentNoOTPAmount
    }
}
