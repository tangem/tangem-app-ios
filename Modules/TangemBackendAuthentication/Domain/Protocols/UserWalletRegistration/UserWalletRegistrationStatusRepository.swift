//
//  UserWalletRegistrationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

package import struct TangemFoundation.UserWalletId

package protocol UserWalletRegistrationStatusRepository: Sendable {
    func retrieve(id: UserWalletId) async -> Bool
    func updates(id: UserWalletId) async -> AsyncStream<Bool>

    func persist(registeredID: UserWalletId) async
    func replaceAll(with newRegisteredIDs: [UserWalletId]) async

    func remove(registeredID: UserWalletId) async
}
