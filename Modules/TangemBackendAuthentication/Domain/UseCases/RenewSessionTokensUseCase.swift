//
//  RenewSessionTokensUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct Foundation.Date
import struct TangemLogger.Logger

actor RenewSessionTokensUseCase {
    private let registerDevice: RegisterDevice
    private let appAttestService: any AppAttestService
    private let sessionAuthenticationClient: any SessionAuthenticationClient

    private let sessionTokensRepository: any SessionTokensRepository
    private let appAttestationStatusRepository: any AppAttestationStatusRepository
    private let deviceRegistrationStatusRepository: any DeviceRegistrationStatusRepository
    private let userWalletRegistrationStatusRepository: any UserWalletRegistrationStatusRepository

    private let deviceKeyManager: DeviceKeyManager
    private let nonceDecryptor: any NonceDecryptor

    private let deviceMetadataProvider: () -> DeviceMetadata
    private let dateProvider: @Sendable () -> Date
    private let analyticsReporter: any BackendAuthenticationNonceAnalyticsReporter
    private let logger: Logger

    private var inFlightRenewalTask: Task<Result<SessionTokens, RenewSessionTokensError>, Never>?

    init(
        registerDevice: @escaping RegisterDevice,
        appAttestService: some AppAttestService,
        sessionAuthenticationClient: some SessionAuthenticationClient,
        sessionTokensRepository: some SessionTokensRepository,
        appAttestationStatusRepository: some AppAttestationStatusRepository,
        deviceRegistrationStatusRepository: some DeviceRegistrationStatusRepository,
        userWalletRegistrationStatusRepository: some UserWalletRegistrationStatusRepository,
        deviceKeyManager: DeviceKeyManager,
        nonceDecryptor: some NonceDecryptor,
        deviceMetadataProvider: @escaping @Sendable @autoclosure () -> DeviceMetadata,
        dateProvider: @escaping @Sendable @autoclosure () -> Date = Date.now,
        analyticsReporter: some BackendAuthenticationNonceAnalyticsReporter,
        logger: Logger
    ) {
        self.registerDevice = registerDevice

        self.appAttestService = appAttestService
        self.sessionAuthenticationClient = sessionAuthenticationClient

        self.sessionTokensRepository = sessionTokensRepository
        self.appAttestationStatusRepository = appAttestationStatusRepository
        self.deviceRegistrationStatusRepository = deviceRegistrationStatusRepository
        self.userWalletRegistrationStatusRepository = userWalletRegistrationStatusRepository

        self.deviceKeyManager = deviceKeyManager
        self.nonceDecryptor = nonceDecryptor

        self.deviceMetadataProvider = deviceMetadataProvider
        self.dateProvider = dateProvider
        self.analyticsReporter = analyticsReporter
        self.logger = logger
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

        do {
            return try await sessionAuthenticationClient.refresh(
                refreshToken: refreshToken.jwt,
                accessToken: cachedTokens.accessToken.jwt
            )
        } catch {
            logger.error("Failed to refresh session tokens from cache, falling back to full authentication", error: error)
            return nil
        }
    }

    private func authenticateNewSession() async throws(RenewSessionTokensError) -> SessionTokens {
        let freshSessionTokensAfterRegistration: SessionTokens?

        do {
            freshSessionTokensAfterRegistration = try await registerDevice()
        } catch {
            throw RenewSessionTokensError.registrationFailure(error)
        }

        if let freshSessionTokensAfterRegistration {
            return freshSessionTokensAfterRegistration
        }

        do {
            return try await authenticate()
        } catch RenewSessionTokensError.clientFailure(.deviceRegistrationMissing) {
            return try await recoverFromMissingDeviceRegistration()
        } catch RenewSessionTokensError.clientFailure(.appAttestRejected) {
            return try await recoverFromAppAttestRejection()
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

        let appAttestToken: SessionAuthenticationRequest.AppAttestToken?
        let appHasAlreadyBeenAttested = appAttestationStatusRepository.retrieve()

        if appHasAlreadyBeenAttested {
            let assertion: AppAssertion? = await assert(decryptedNonceBytes: decryptedNonceBytes)
            appAttestToken = assertion.map(SessionAuthenticationRequest.AppAttestToken.init(assertion:))
        } else {
            let attestation: AppAttestation? = await attest(decryptedNonceBytes: decryptedNonceBytes)
            appAttestToken = attestation.map(SessionAuthenticationRequest.AppAttestToken.init(attestation:))
        }

        let deviceMetadata = deviceMetadataProvider()

        let authenticationSignature: DeviceSignature

        do {
            let signaturePayload = DeviceSignaturePayloadFactory.make(
                devicePublicKey: devicePublicKey,
                decryptedNonce: decryptedNonce,
                attestationToken: appAttestToken?.object,
                metadata: deviceMetadata
            )

            authenticationSignature = try await deviceKeyManager.sign(data: signaturePayload)
        } catch {
            throw RenewSessionTokensError.deviceKeyFailure(error)
        }

        let request = SessionAuthenticationRequest(
            devicePublicKey: devicePublicKey,
            decryptedNonce: decryptedNonce,
            metadata: deviceMetadata,
            signature: authenticationSignature,
            appAttestToken: appAttestToken
        )

        let sessionTokens: SessionTokens
        do {
            sessionTokens = try await sessionAuthenticationClient.authenticate(request: request)
        } catch {
            throw RenewSessionTokensError.clientFailure(error)
        }

        guard appAttestToken != nil else {
            return sessionTokens
        }

        let backendAcceptedAppAttestToken = sessionTokens.refreshToken != nil

        let shouldPersistAppAttestationStatus = !appHasAlreadyBeenAttested && backendAcceptedAppAttestToken
        if shouldPersistAppAttestationStatus {
            appAttestationStatusRepository.persist(isAppAttested: true)
        }

        let shouldClearAppAttestationStatus = appHasAlreadyBeenAttested && !backendAcceptedAppAttestToken
        if shouldClearAppAttestationStatus {
            appAttestationStatusRepository.persist(isAppAttested: false)
            logger.debug("App attestation status cleared, because backend did not accept app assertion")
        }

        return sessionTokens
    }

    /// On `.deviceRegistrationMissing` error we register the device again, exactly once,
    /// and reuse the tokens from a successful registration directly.
    /// If registration reports the device as already registered (no tokens),
    /// we retry `authenticate()` exactly once more, with no further recovery.
    private func recoverFromMissingDeviceRegistration() async throws(RenewSessionTokensError) -> SessionTokens {
        appAttestationStatusRepository.persist(isAppAttested: false)
        deviceRegistrationStatusRepository.persist(isRegistered: false)

        let freshSessionTokensAfterRegistration: SessionTokens?

        do {
            freshSessionTokensAfterRegistration = try await registerDevice()
        } catch {
            throw RenewSessionTokensError.registrationFailure(error)
        }

        let recoveredSessionTokens: SessionTokens

        if let freshSessionTokensAfterRegistration {
            recoveredSessionTokens = freshSessionTokensAfterRegistration
        } else {
            recoveredSessionTokens = try await authenticate()
        }

        await userWalletRegistrationStatusRepository.replaceAll(with: recoveredSessionTokens.userWalletIDs)
        return recoveredSessionTokens
    }

    private func recoverFromAppAttestRejection() async throws(RenewSessionTokensError) -> SessionTokens {
        appAttestationStatusRepository.persist(isAppAttested: false)
        logger.debug("App attestation status cleared, because backend rejected app assertion")

        return try await authenticate()
    }

    private func attest(decryptedNonceBytes: Data) async -> AppAttestation? {
        do {
            return try await appAttestService.attest(decryptedNonceBytes: decryptedNonceBytes)
        } catch AppAttestServiceError.deviceCheckUnsupported {
            logger.debug("App attestation is not supported, proceeding without it")
            return nil
        } catch {
            logger.error("Failed to generate app attestation", error: error)
            return nil
        }
    }

    private func assert(decryptedNonceBytes: Data) async -> AppAssertion? {
        do {
            return try await appAttestService.assert(decryptedNonceBytes: decryptedNonceBytes)
        } catch AppAttestServiceError.assertionKeyCorrupted {
            appAttestationStatusRepository.persist(isAppAttested: false)
            logger.error(
                "App attestation status cleared, because stored key for app assertion was malformed.",
                error: AppAttestServiceError.assertionKeyCorrupted
            )
            return nil
        } catch AppAttestServiceError.assertionKeyNotFound {
            appAttestationStatusRepository.persist(isAppAttested: false)
            logger.error(
                "App attestation status cleared, because stored key for app assertion was not found.",
                error: AppAttestServiceError.assertionKeyNotFound
            )
            return nil
        } catch AppAttestServiceError.deviceCheckUnsupported {
            logger.debug("App assertion is not supported, proceeding without it")
            return nil
        } catch {
            logger.error("Failed to generate app assertion", error: error)
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
            switch error {
            case .requestNonceTimeout:
                analyticsReporter.reportAuthenticationNonceTimeout()

            case .requestNonceFailed,
                 .authenticateFailed,
                 .authenticationRejected,
                 .deviceRegistrationMissing,
                 .appAttestRejected,
                 .refreshFailed:
                break
            }

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
            logger.error("Failed to delete session tokens after authentication was rejected", error: error)
        }
    }
}
