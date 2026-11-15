//
//  BackendAuthenticationNonceAnalyticsReporter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol BackendAuthenticationNonceAnalyticsReporter: Sendable {
    func reportDeviceNonceTimeout()
    func reportAuthenticationNonceTimeout()
    func reportMobileUserWalletNonceTimeout()
}
