//
//  RegisterUserWalletUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.Data
public import struct TangemFoundation.UserWalletId

public struct RegisterUserWalletUseCase {
    public func callAsFunction(
        id: UserWalletId,
        publicKey: Data,
        signer: some UserWalletSigner
    ) async throws {
        // [REDACTED_TODO_COMMENT]
    }
}
