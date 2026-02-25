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

    func makeSendAnalyticsLogger(sendType: CommonSendAnalyticsLogger.SendType) -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(sendType: sendType)
    }
}
