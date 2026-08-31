//
//  BackendAuthenticationStorageCleaner.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct BackendAuthenticationStorageCleaner: Sendable {
    let devicePrivateKeyRepository: any DevicePrivateKeyRepository
    let sessionTokensRepository: any SessionTokensRepository

    public func clean() async {
        do {
            try await devicePrivateKeyRepository.delete()
        } catch _ {
            // [REDACTED_TODO_COMMENT]
        }

        do {
            try await sessionTokensRepository.delete()
        } catch _ {
            // [REDACTED_TODO_COMMENT]
        }
    }
}
