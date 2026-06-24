//
//  CryptoAddressProcessorAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol CryptoAddressProcessorAnalyticsLogger {
    func logSendAddressEntered(isAddressValid: Bool, addressSource: Analytics.DestinationAddressSource)
}
