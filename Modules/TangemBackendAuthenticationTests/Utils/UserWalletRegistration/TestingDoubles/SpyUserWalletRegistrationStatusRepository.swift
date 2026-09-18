//
//  SpyUserWalletRegistrationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import os.lock
import struct TangemFoundation.UserWalletId
@testable import TangemBackendAuthentication

final class SpyUserWalletRegistrationStatusRepository: UserWalletRegistrationStatusRepository {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var retrieveResult: Bool {
        get { state.withLock(\.retrieveResult) }
        set { state.withLock { $0.retrieveResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    func retrieve(id: UserWalletId) -> Bool {
        state.withLock { $0.receivedMessages.append(.retrieve(id)) }
        return retrieveResult
    }

    func persist(isRegistered: Bool, id: UserWalletId) {
        state.withLock { $0.receivedMessages.append(.persist(isRegistered: isRegistered, id: id)) }
    }
}

extension SpyUserWalletRegistrationStatusRepository {
    enum Message: Equatable {
        case retrieve(UserWalletId)
        case persist(isRegistered: Bool, id: UserWalletId)
    }

    private struct State {
        var retrieveResult: Bool = false
        var receivedMessages: [Message] = []
    }
}
