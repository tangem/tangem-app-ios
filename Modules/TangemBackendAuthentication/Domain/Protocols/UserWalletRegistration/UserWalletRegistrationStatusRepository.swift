//
//  UserWalletRegistrationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemFoundation.UserWalletId

protocol UserWalletRegistrationStatusRepository: Sendable {
    func retrieve(id: UserWalletId) async -> Bool

    func persist(registeredID: UserWalletId) async
    func replaceAll(with newRegisteredIDs: [UserWalletId]) async

    func remove(registeredID: UserWalletId) async
}
