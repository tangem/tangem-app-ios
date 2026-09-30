//
//  BackendAuthenticationAnalyticsReporter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol BackendAuthenticationAnalyticsReporter: Sendable {
    func reportDeviceNonceTimeout()
    func reportAuthenticationNonceTimeout()
    func reportMobileUserWalletNonceTimeout()
}
