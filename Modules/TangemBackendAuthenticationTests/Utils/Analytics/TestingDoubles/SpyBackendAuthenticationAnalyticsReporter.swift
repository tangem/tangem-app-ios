//
//  SpyBackendAuthenticationAnalyticsReporter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import os.lock
@testable import TangemBackendAuthentication

final class SpyBackendAuthenticationAnalyticsReporter: BackendAuthenticationAnalyticsReporter {
    private let state = OSAllocatedUnfairLock(initialState: [Message]())

    var receivedMessages: [Message] {
        state.withLock(\.self)
    }

    func reportDeviceNonceTimeout() {
        state.withLock { $0.append(.reportDeviceNonceTimeout) }
    }

    func reportAuthenticationNonceTimeout() {
        state.withLock { $0.append(.reportAuthenticationNonceTimeout) }
    }

    func reportMobileUserWalletNonceTimeout() {
        state.withLock { $0.append(.reportMobileUserWalletNonceTimeout) }
    }
}

extension SpyBackendAuthenticationAnalyticsReporter {
    enum Message: Equatable {
        case reportDeviceNonceTimeout
        case reportAuthenticationNonceTimeout
        case reportMobileUserWalletNonceTimeout
    }
}
