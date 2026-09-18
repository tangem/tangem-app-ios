//
//  RegisterDeviceUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

typealias RegisterDevice = @Sendable () async throws(RegisterDeviceError) -> SessionTokens?

public actor RegisterDeviceUseCase {
    private let appAttestService: any AppAttestService
    private let registrationClient: any DeviceRegistrationClient
    private let registrationStatusRepository: any DeviceRegistrationStatusRepository
    private let sessionTokensRepository: any SessionTokensRepository

    private let deviceKeyManager: DeviceKeyManager
    private let nonceDecryptor: any NonceDecryptor

    private let deviceMetadataProvider: @Sendable () -> DeviceMetadata

    private var inFlightRegistrationTask: Task<Result<SessionTokens?, RegisterDeviceError>, Never>?

    init(
        appAttestService: some AppAttestService,
        registrationClient: some DeviceRegistrationClient,
        registrationStatusRepository: some DeviceRegistrationStatusRepository,
        sessionTokensRepository: some SessionTokensRepository,
        deviceKeyManager: DeviceKeyManager,
        nonceDecryptor: some NonceDecryptor,
        deviceMetadataProvider: @escaping @Sendable @autoclosure () -> DeviceMetadata
    ) {
        self.appAttestService = appAttestService
        self.registrationClient = registrationClient
        self.registrationStatusRepository = registrationStatusRepository
        self.sessionTokensRepository = sessionTokensRepository

        self.deviceKeyManager = deviceKeyManager
        self.nonceDecryptor = nonceDecryptor

        self.deviceMetadataProvider = deviceMetadataProvider
    }

    /// Registers this device with the backend, if it hasn't been already.
    ///
    /// - Returns: The freshly issued ``SessionTokens`` when this call actually registered the device.
    /// `nil` when the device was already registered.
    /// Obtain a session separately (e.g. via ``RenewSessionTokensUseCase``) if needed.
    @discardableResult
    public func callAsFunction() async throws(RegisterDeviceError) -> SessionTokens? {
        let deviceIsAlreadyRegistered = registrationStatusRepository.retrieve()

        guard !deviceIsAlreadyRegistered else { return nil }

        if let inFlightRegistrationTask {
            return try await inFlightRegistrationTask.value.get()
        }

        let task: Task<Result<SessionTokens?, RegisterDeviceError>, Never> = Task {
            do throws(RegisterDeviceError) {
                return .success(try await register())
            } catch {
                registrationStatusRepository.persist(isRegistered: false)
                return .failure(error)
            }
        }
        inFlightRegistrationTask = task

        defer { inFlightRegistrationTask = nil }
        return try await task.value.get()
    }

    private func register() async throws(RegisterDeviceError) -> SessionTokens? {
        let devicePublicKey = try await resolveDevicePublicKey()
        let cipheredNonce = try await requestCipheredNonce(for: devicePublicKey)

        let decryptedNonceBytes = try decrypt(cipheredNonce: cipheredNonce)
        let decryptedNonce = String(decoding: decryptedNonceBytes, as: UTF8.self)

        let attestationToken = await generateAttestationToken(for: decryptedNonceBytes)
        let deviceMetadata = deviceMetadataProvider()

        let signature: DeviceSignature

        do {
            let signaturePayload = DeviceSignaturePayloadFactory.make(
                devicePublicKey: devicePublicKey,
                decryptedNonce: decryptedNonce,
                attestationToken: attestationToken,
                metadata: deviceMetadata
            )

            signature = try await deviceKeyManager.sign(data: signaturePayload)
        } catch {
            throw RegisterDeviceError.deviceKeyFailure(error)
        }

        let request = DeviceRegistrationRequest(
            devicePublicKey: devicePublicKey,
            decryptedNonce: decryptedNonce,
            metadata: deviceMetadata,
            signature: signature,
            appAttestationToken: attestationToken
        )
        let sessionTokens = try await registerDevice(request: request)

        if let sessionTokens {
            try await persist(sessionTokens: sessionTokens)
        }
        registrationStatusRepository.persist(isRegistered: true)

        return sessionTokens
    }

    private func generateAttestationToken(for decryptedNonceBytes: Data) async -> Data? {
        do {
            return try await appAttestService.generateAttestationToken(for: decryptedNonceBytes)
        } catch {
            // [REDACTED_TODO_COMMENT]
            return nil
        }
    }

    private func resolveDevicePublicKey() async throws(RegisterDeviceError) -> DevicePublicKey {
        do {
            return try await deviceKeyManager.publicKey
        } catch {
            throw RegisterDeviceError.deviceKeyFailure(error)
        }
    }

    private func requestCipheredNonce(for devicePublicKey: DevicePublicKey) async throws(RegisterDeviceError) -> String {
        do {
            return try await registrationClient.requestCipheredNonce(devicePublicKey: devicePublicKey)
        } catch {
            throw RegisterDeviceError.clientFailure(error)
        }
    }

    private func decrypt(cipheredNonce: String) throws(RegisterDeviceError) -> Data {
        do {
            return try nonceDecryptor.decrypt(cipheredNonce: cipheredNonce)
        } catch {
            throw RegisterDeviceError.nonceDecryptionFailure(error)
        }
    }

    private func registerDevice(request: DeviceRegistrationRequest) async throws(RegisterDeviceError) -> SessionTokens? {
        do {
            return try await registrationClient.register(request: request)
        } catch DeviceRegistrationClientError.alreadyRegistered {
            return nil
        } catch {
            throw RegisterDeviceError.clientFailure(error)
        }
    }
}

// MARK: - Persistence

extension RegisterDeviceUseCase {
    private func persist(sessionTokens: SessionTokens) async throws(RegisterDeviceError) {
        do {
            try await sessionTokensRepository.persist(tokens: sessionTokens)
        } catch {
            throw RegisterDeviceError.repositoryFailure(error)
        }
    }
}
