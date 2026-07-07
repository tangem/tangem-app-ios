//
//  SendDestinationAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SendDestinationAnalyticsLogger {
    func logSendAddressEntered(isAddressValid: Bool, addressSource: Analytics.DestinationAddressSource)
    func logQRScannerOpened()

    func logDestinationStepOpened()
    func logDestinationStepReopened()

    func logAddressBookWidgetShown()
    func logAddressBookContactSelected(_ contact: AddressBookContact)
    func logAddressBookAddressSubstituted(_ contact: AddressBookContact)

    func setDestinationAnalyticsProvider(_ analyticsProvider: (any AccountModelAnalyticsProviding)?)
}
