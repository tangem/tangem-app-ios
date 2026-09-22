//
//  BackendAuthenticationStorageCleaner.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemLogger.Logger

public struct BackendAuthenticationStorageCleaner: Sendable {
    let devicePrivateKeyRepository: any DevicePrivateKeyRepository
    let sessionTokensRepository: any SessionTokensRepository
    let logger: Logger

    public func clean() async {
        do {
            try await devicePrivateKeyRepository.delete()
        } catch {
            logger.error("Failed to delete device private key while cleaning backend authentication storage", error: error)
        }

        do {
            try await sessionTokensRepository.delete()
        } catch {
            logger.error("Failed to delete session tokens while cleaning backend authentication storage", error: error)
        }
    }
}
