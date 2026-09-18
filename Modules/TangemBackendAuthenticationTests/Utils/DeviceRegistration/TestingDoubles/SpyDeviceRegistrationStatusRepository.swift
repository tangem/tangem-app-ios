//
//  SpyDeviceRegistrationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import os.lock
@testable import TangemBackendAuthentication

final class SpyDeviceRegistrationStatusRepository: DeviceRegistrationStatusRepository {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var retrieveResult: Bool {
        get { state.withLock(\.retrieveResult) }
        set { state.withLock { $0.retrieveResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    func retrieve() -> Bool {
        state.withLock { $0.receivedMessages.append(.retrieve) }
        return retrieveResult
    }

    func persist(isRegistered: Bool) {
        state.withLock { $0.receivedMessages.append(.persist(isRegistered: isRegistered)) }
    }
}

extension SpyDeviceRegistrationStatusRepository {
    enum Message: Equatable {
        case retrieve
        case persist(isRegistered: Bool)
    }

    private struct State {
        var retrieveResult: Bool = false
        var receivedMessages: [Message] = []
    }
}
