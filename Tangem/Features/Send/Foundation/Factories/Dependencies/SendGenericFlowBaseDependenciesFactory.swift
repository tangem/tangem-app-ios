//
//  SendGenericFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUI.TokenIconInfo

protocol SendGenericFlowBaseDependenciesFactory {}

// MARK: - Common dependencies

extension SendGenericFlowBaseDependenciesFactory {
    // MARK: - Analytics

    func makeSendAnalyticsLogger(sendType: CommonSendAnalyticsLogger.SendType, coordinatorSource: SendCoordinator.Source = .main) -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(sendType: sendType, coordinatorSource: coordinatorSource, addressBookAnalyticsLogger: CommonAddressBookAnalyticsLogger())
    }

    func makeSwapAnalyticsLogger() -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(sendType: .swap, coordinatorSource: .main, addressBookAnalyticsLogger: CommonAddressBookAnalyticsLogger())
    }

    func makeSendWithSwapAnalyticsLogger(
        sendType: CommonSendAnalyticsLogger.SendType,
        coordinatorSource: SendCoordinator.Source = .main
    ) -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(sendType: sendType, coordinatorSource: coordinatorSource, addressBookAnalyticsLogger: CommonAddressBookAnalyticsLogger())
    }
}
