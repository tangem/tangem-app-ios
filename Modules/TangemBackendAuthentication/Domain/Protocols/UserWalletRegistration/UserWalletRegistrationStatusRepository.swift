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
    func persist(isRegistered: Bool, id: UserWalletId) async
}
