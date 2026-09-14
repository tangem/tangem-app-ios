//
//  DynamicAddressesAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol DynamicAddressesAnalyticsLogger {
    func logDynamicAddressesScreenOpened()
    func logButtonEnableDynamicAddresses()
    func logDynamicAddressesEnabled()
    func logButtonDisableDynamicAddresses()
    func logDynamicAddressesDisabled()
    func logDynamicAddressesNoticeUnavailable()
    func logDynamicAddressesErrorUnavailable()
    func logTokenNoticeNotEnoughFee(feeCurrencyBalance: Decimal)
    func logDynamicAddressesNoticeFundsFound()
}
