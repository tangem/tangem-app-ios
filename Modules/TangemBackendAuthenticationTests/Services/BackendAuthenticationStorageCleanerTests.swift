//
//  BackendAuthenticationStorageCleanerTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLogger
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct BackendAuthenticationStorageCleanerTests {
    @Test
    func cleanDeletesBackendAuthenticationStorage() async throws {
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(.successStub)
        devicePrivateKeyRepository.deleteResult = Result.success(())

        let deviceKeyManager = DeviceKeyManager(privateKeyRepository: devicePrivateKeyRepository)
        try await deviceKeyManager.waitForPrivateKeyRetrieval()

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.deleteResult = Result.success(())

        let appAttestKeyIDRepository = SpyKeychainRepository()
        appAttestKeyIDRepository.deleteResult = Result.success(())

        let sut = makeSUT(
            deviceKeyManager: deviceKeyManager,
            sessionTokensRepository: sessionTokensRepository,
            appAttestKeyIDRepository: appAttestKeyIDRepository
        )

        await sut.clean()

        #expect(devicePrivateKeyRepository.receivedMessages == [.retrieve, .delete])
        #expect(sessionTokensRepository.receivedMessages == [.delete])
        #expect(appAttestKeyIDRepository.receivedMessages == [.delete])
    }

    @Test
    func cleanAttemptsEveryDeletionEvenWhenAllOfThemFail() async throws {
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(.successStub)

        let deviceKeyManager = DeviceKeyManager(privateKeyRepository: devicePrivateKeyRepository)
        try await deviceKeyManager.waitForPrivateKeyRetrieval()

        let sessionTokensRepository = SpySessionTokensRepository()
        let appAttestKeyIDRepository = SpyKeychainRepository()

        let sut = makeSUT(
            deviceKeyManager: deviceKeyManager,
            sessionTokensRepository: sessionTokensRepository,
            appAttestKeyIDRepository: appAttestKeyIDRepository
        )

        await sut.clean()

        #expect(devicePrivateKeyRepository.receivedMessages == [.retrieve, .delete])
        #expect(sessionTokensRepository.receivedMessages == [.delete])
        #expect(appAttestKeyIDRepository.receivedMessages == [.delete])
    }
}

// MARK: - Factory methods

extension BackendAuthenticationStorageCleanerTests {
    private func makeSUT(
        deviceKeyManager: DeviceKeyManager,
        sessionTokensRepository: some SessionTokensRepository = SpySessionTokensRepository(),
        appAttestKeyIDRepository: some KeychainRepository = SpyKeychainRepository()
    ) -> BackendAuthenticationStorageCleaner {
        BackendAuthenticationStorageCleaner(
            deviceKeyManager: deviceKeyManager,
            sessionTokensRepository: sessionTokensRepository,
            appAttestKeyIDRepository: appAttestKeyIDRepository,
            logger: Logger(category: OSLogCategory(name: "Tests"))
        )
    }
}

private extension DeviceKeyManager {
    func waitForPrivateKeyRetrieval() async throws {
        _ = try await publicKey
    }
}
