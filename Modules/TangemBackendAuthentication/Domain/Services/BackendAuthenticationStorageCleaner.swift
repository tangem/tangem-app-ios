//
//  BackendAuthenticationStorageCleaner.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemLogger.Logger

public struct BackendAuthenticationStorageCleaner: Sendable {
    let deviceKeyManager: DeviceKeyManager
    let sessionTokensRepository: any SessionTokensRepository
    let appAttestKeyIDRepository: any KeychainRepository

    let logger: Logger

    public func clean() async {
        logger.debug("Backend authentication storage cleaning started.")

        async let deviceKeyTask = deleteDeviceKey()
        async let sessionTokensTask = deleteSessionTokens()
        async let appAttestKeyIDTask = deleteAppAttestKeyID()

        await deviceKeyTask
        await sessionTokensTask
        await appAttestKeyIDTask

        logger.debug("Backend authentication storage cleaning finished.")
    }

    private func deleteDeviceKey() async {
        do {
            try await deviceKeyManager.deleteKey()
            logger.debug("Device key deleted.")
        } catch {
            logger.error("Failed to delete device key.", error: error)
        }
    }

    private func deleteSessionTokens() async {
        do {
            try await sessionTokensRepository.delete()
            logger.debug("Session tokens deleted.")
        } catch {
            logger.error("Failed to delete session tokens.", error: error)
        }
    }

    private func deleteAppAttestKeyID() async {
        do {
            try await appAttestKeyIDRepository.delete()
            logger.debug("AppAttest keyID deleted.")
        } catch {
            logger.error("Failed to delete app attest keyID.", error: error)
        }
    }
}
