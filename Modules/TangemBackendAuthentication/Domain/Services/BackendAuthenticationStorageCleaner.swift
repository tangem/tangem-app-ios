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
            logger.debug("Device private key cleared.")
        } catch {
            logger.error("Failed to clear device private key.", error: error)
        }

        do {
            try await sessionTokensRepository.delete()
            logger.debug("Session tokens cleared.")
        } catch {
            logger.error("Failed to clear session tokens.", error: error)
        }
    }
}
