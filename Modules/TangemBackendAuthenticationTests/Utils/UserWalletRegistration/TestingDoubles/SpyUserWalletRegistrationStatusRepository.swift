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

    func persist(registeredID: UserWalletId) {
        state.withLock { $0.receivedMessages.append(.persist(registeredID)) }
    }

    func replaceAll(with newRegisteredIDs: [UserWalletId]) {
        state.withLock { $0.receivedMessages.append(.replaceAll(newRegisteredIDs)) }
    }

    func remove(registeredID: UserWalletId) {
        state.withLock { $0.receivedMessages.append(.remove(registeredID)) }
    }
}

extension SpyUserWalletRegistrationStatusRepository {
    enum Message: Equatable {
        case retrieve(UserWalletId)
        case persist(UserWalletId)
        case replaceAll([UserWalletId])
        case remove(UserWalletId)
    }

    private struct State {
        var retrieveResult: Bool = false
        var receivedMessages: [Message] = []
    }
}
