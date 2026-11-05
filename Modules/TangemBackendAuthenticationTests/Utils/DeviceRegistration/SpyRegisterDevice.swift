//
//  SpyRegisterDevice.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import os.lock
import Testing
@testable import TangemBackendAuthentication

final class SpyRegisterDevice: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var registerDeviceResults: [Result<SessionTokens?, RegisterDeviceError>] {
        get { state.withLock(\.registerDeviceResults) }
        set { state.withLock { $0.registerDeviceResults = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    func callAsFunction() async throws(RegisterDeviceError) -> SessionTokens? {
        let registerDeviceResult = state.withLock { state -> Result<SessionTokens?, RegisterDeviceError>? in
            state.receivedMessages.append(.registerDevice)
            return state.registerDeviceResults.isEmpty ? nil : state.registerDeviceResults.removeFirst()
        }

        guard let registerDeviceResult else {
            Issue.record("Unexpected registerDevice call: no registerDeviceResults left")
            return nil
        }

        return try registerDeviceResult.get()
    }
}

extension SpyRegisterDevice {
    enum Message: Equatable {
        case registerDevice
    }

    private struct State {
        var registerDeviceResults: [Result<SessionTokens?, RegisterDeviceError>] = []
        var receivedMessages: [Message] = []
    }
}
