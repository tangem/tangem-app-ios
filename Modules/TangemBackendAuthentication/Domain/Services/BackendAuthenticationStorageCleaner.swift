//
//  BackendAuthenticationStorageCleaner.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]

public struct BackendAuthenticationStorageCleaner {
    private let devicePrivateKeyRepository: any DevicePrivateKeyRepository
    private let sessionTokensRepository: any SessionTokensRepository

    init(
        devicePrivateKeyRepository: some DevicePrivateKeyRepository,
        sessionTokensRepository: some SessionTokensRepository
    ) {
        self.devicePrivateKeyRepository = devicePrivateKeyRepository
        self.sessionTokensRepository = sessionTokensRepository
    }

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
