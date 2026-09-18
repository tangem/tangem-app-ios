//
//  RenewSessionTokensUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct Foundation.Date

actor RenewSessionTokensUseCase {
    private let registerDevice: RegisterDevice
    private let appAttestService: any AppAttestService
    private let sessionAuthenticationClient: any SessionAuthenticationClient
    private let sessionTokensRepository: any SessionTokensRepository

    private let deviceKeyManager: DeviceKeyManager
    private let nonceDecryptor: any NonceDecryptor

    private let deviceMetadataProvider: () -> DeviceMetadata
    private let dateProvider: @Sendable () -> Date

    private var inFlightRenewalTask: Task<Result<SessionTokens, RenewSessionTokensError>, Never>?

    init(
        registerDevice: @escaping RegisterDevice,
        appAttestService: some AppAttestService,
        sessionAuthenticationClient: some SessionAuthenticationClient,
        sessionTokensRepository: some SessionTokensRepository,
        deviceKeyManager: DeviceKeyManager,
        nonceDecryptor: some NonceDecryptor,
        deviceMetadataProvider: @escaping @Sendable @autoclosure () -> DeviceMetadata,
        dateProvider: @escaping @Sendable @autoclosure () -> Date = Date.now
    ) {
        self.registerDevice = registerDevice

        self.appAttestService = appAttestService
        self.sessionAuthenticationClient = sessionAuthenticationClient
        self.sessionTokensRepository = sessionTokensRepository

        self.deviceKeyManager = deviceKeyManager
        self.nonceDecryptor = nonceDecryptor

        self.deviceMetadataProvider = deviceMetadataProvider
        self.dateProvider = dateProvider
    }

    func callAsFunction() async throws(RenewSessionTokensError) -> SessionTokens {
        if let inFlightRenewalTask {
            return try await inFlightRenewalTask.value.get()
        }

        let task: Task<Result<SessionTokens, RenewSessionTokensError>, Never> = Task {
            do throws(RenewSessionTokensError) {
                return .success(try await renew())
            } catch {
                return .failure(error)
            }
        }
        inFlightRenewalTask = task

        defer { inFlightRenewalTask = nil }
        return try await task.value.get()
    }

    private func renew() async throws(RenewSessionTokensError) -> SessionTokens {
        let renewedTokens: SessionTokens

        if let tokensAfterRefresh = try await refreshExistingSession() {
            renewedTokens = tokensAfterRefresh
        } else {
            renewedTokens = try await authenticateNewSession()
        }

        try await persist(sessionTokens: renewedTokens)
        return renewedTokens
    }

    private func refreshExistingSession() async throws(RenewSessionTokensError) -> SessionTokens? {
        guard
            let cachedTokens = try await retrieveCachedTokens(),
            let refreshToken = cachedTokens.refreshToken,
            isNotExpired(refreshToken)
        else {
            return nil
        }

        return try? await sessionAuthenticationClient.refresh(
            refreshToken: refreshToken.jwt,
            accessToken: cachedTokens.accessToken.jwt
        )
    }

    private func authenticateNewSession() async throws(RenewSessionTokensError) -> SessionTokens {
        do {
            return try await authenticate()
        } catch RenewSessionTokensError.clientFailure(.deviceRegistrationMissing) {
            return try await recoverFromMissingDeviceRegistration()
        } catch RenewSessionTokensError.clientFailure(.authenticationRejected) {
            await deleteSessionTokens()
            throw RenewSessionTokensError.clientFailure(.authenticationRejected)
        }
    }

    private func isNotExpired(_ refreshToken: SessionTokens.Token) -> Bool {
        dateProvider() < refreshToken.expiresAt
    }
}

// MARK: - Authentication

extension RenewSessionTokensUseCase {
    private func authenticate() async throws(RenewSessionTokensError) -> SessionTokens {
        let devicePublicKey = try await resolveDevicePublicKey()
        let cipheredNonce = try await requestCipheredNonce(for: devicePublicKey)

        let decryptedNonceBytes = try decrypt(cipheredNonce: cipheredNonce)
        let decryptedNonce = String(decoding: decryptedNonceBytes, as: UTF8.self)

        let attestationToken = await generateAttestationToken(for: decryptedNonceBytes)
        let deviceMetadata = deviceMetadataProvider()

        let authenticationSignature: DeviceSignature

        do {
            let signaturePayload = DeviceSignaturePayloadFactory.make(
                devicePublicKey: devicePublicKey,
                decryptedNonce: decryptedNonce,
                attestationToken: attestationToken,
                metadata: deviceMetadata
            )

            authenticationSignature = try await deviceKeyManager.sign(data: signaturePayload)
        } catch {
            throw RenewSessionTokensError.deviceKeyFailure(error)
        }

        do {
            return try await sessionAuthenticationClient.authenticate(
                devicePublicKey: devicePublicKey,
                decryptedNonce: decryptedNonce,
                metadata: deviceMetadata,
                signature: authenticationSignature,
                attestationToken: attestationToken
            )
        } catch {
            throw RenewSessionTokensError.clientFailure(error)
        }
    }

    /// On `.deviceRegistrationMissing` error we register the device again, exactly once,
    /// and reuse the tokens from a successful registration directly.
    /// If registration reports the device as already registered (no tokens),
    /// we retry `authenticate()` exactly once more, with no further recovery.
    private func recoverFromMissingDeviceRegistration() async throws(RenewSessionTokensError) -> SessionTokens {
        let freshSessionTokensAfterRegistration: SessionTokens?

        do {
            freshSessionTokensAfterRegistration = try await registerDevice()
        } catch {
            throw RenewSessionTokensError.registrationFailure(error)
        }

        if let freshSessionTokensAfterRegistration {
            return freshSessionTokensAfterRegistration
        }

        return try await authenticate()
    }

    private func generateAttestationToken(for decryptedNonceBytes: Data) async -> Data? {
        do {
            return try await appAttestService.generateAttestationToken(for: decryptedNonceBytes)
        } catch {
            // [REDACTED_TODO_COMMENT]
            return nil
        }
    }

    private func resolveDevicePublicKey() async throws(RenewSessionTokensError) -> DevicePublicKey {
        do {
            return try await deviceKeyManager.publicKey
        } catch {
            throw RenewSessionTokensError.deviceKeyFailure(error)
        }
    }

    private func requestCipheredNonce(for devicePublicKey: DevicePublicKey) async throws(RenewSessionTokensError) -> String {
        do {
            return try await sessionAuthenticationClient.requestCipheredNonce(devicePublicKey: devicePublicKey)
        } catch {
            throw RenewSessionTokensError.clientFailure(error)
        }
    }

    private func decrypt(cipheredNonce: String) throws(RenewSessionTokensError) -> Data {
        do {
            return try nonceDecryptor.decrypt(cipheredNonce: cipheredNonce)
        } catch {
            throw RenewSessionTokensError.nonceDecryptionFailure(error)
        }
    }
}

// MARK: - Persistence

extension RenewSessionTokensUseCase {
    private func retrieveCachedTokens() async throws(RenewSessionTokensError) -> SessionTokens? {
        do {
            return try await sessionTokensRepository.retrieve()
        } catch {
            throw RenewSessionTokensError.repositoryFailure(error)
        }
    }

    private func persist(sessionTokens: SessionTokens) async throws(RenewSessionTokensError) {
        do {
            try await sessionTokensRepository.persist(tokens: sessionTokens)
        } catch {
            throw RenewSessionTokensError.repositoryFailure(error)
        }
    }

    private func deleteSessionTokens() async {
        do {
            try await sessionTokensRepository.delete()
        } catch {
            // [REDACTED_TODO_COMMENT]
        }
    }
}
