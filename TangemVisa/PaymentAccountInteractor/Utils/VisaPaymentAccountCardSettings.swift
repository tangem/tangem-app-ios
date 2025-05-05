//
//  VisaPaymentAccountCardSettings.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct VisaPaymentAccountCardSettings {
    public let initialized: Bool
    public let isOwner: Bool
    public let disableDate: Date
    public let otpState: VisaOTPStateSettings
    public let limits: VisaLimits
}

public struct VisaOTPStateSettings {
    public let oldValue: VisaOTPState
    public let newValue: VisaOTPState
    public let changeDate: Date
}

public struct VisaOTPState {
    public let otp: Data
    public let counter: Int
}
