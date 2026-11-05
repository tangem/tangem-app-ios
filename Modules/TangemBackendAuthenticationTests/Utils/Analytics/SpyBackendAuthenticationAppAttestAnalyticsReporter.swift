//
//  SpyBackendAuthenticationAppAttestAnalyticsReporter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import os.lock
@testable import TangemBackendAuthentication

final class SpyBackendAuthenticationAppAttestAnalyticsReporter: BackendAuthenticationAppAttestAnalyticsReporter {
    private let state = OSAllocatedUnfairLock(initialState: [Message]())

    var receivedMessages: [Message] {
        state.withLock(\.self)
    }

    func reportAttestationFailed(with error: AppAttestServiceError) {
        state.withLock { $0.append(.reportAttestationFailed(error)) }
    }

    func reportAssertionFailed(with error: AppAttestServiceError) {
        state.withLock { $0.append(.reportAssertionFailed(error)) }
    }
}

extension SpyBackendAuthenticationAppAttestAnalyticsReporter {
    enum Message {
        case reportAttestationFailed(AppAttestServiceError)
        case reportAssertionFailed(AppAttestServiceError)
    }
}
