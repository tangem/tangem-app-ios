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
    private let state: OSAllocatedUnfairLock<State>

    var retrieveResult: Bool {
        get { state.withLock(\.retrieveResult) }
        set { state.withLock { $0.retrieveResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    init(retrieveResult: Bool = false) {
        state = OSAllocatedUnfairLock(initialState: State(retrieveResult: retrieveResult))
    }

    func retrieve() -> Bool {
        state.withLock {
            $0.receivedMessages.append(.retrieve)
            return $0.retrieveResult
        }
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
        var receivedMessages: [Message] = []
        var retrieveResult: Bool
    }
}
