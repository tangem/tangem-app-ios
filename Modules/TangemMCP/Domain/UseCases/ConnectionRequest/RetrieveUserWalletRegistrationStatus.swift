//
//  RetrieveUserWalletRegistrationStatus.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct TangemFoundation.UserWalletId

public typealias RetrieveUserWalletRegistrationStatus = @Sendable (_ userWalletID: UserWalletId) async -> Bool
