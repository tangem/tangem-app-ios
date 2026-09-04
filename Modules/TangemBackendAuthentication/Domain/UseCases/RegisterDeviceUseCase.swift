//
//  RegisterDeviceUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

public actor RegisterDeviceUseCase {
    private let appAttestService: any AppAttestService
    private let deviceRegistrationClient: any DeviceRegistrationClient
    private let sessionTokensRepository: any SessionTokensRepository
    private let deviceRegistrationStatusRepository: any DeviceRegistrationStatusRepository

    private let deviceKeyManager: DeviceKeyManager
    private let nonceDecryptor: any NonceDecryptor

    private let deviceMetadata: DeviceMetadata

    private var inFlightRegistrationTask: Task<Result<SessionTokens?, RegisterDeviceError>, Never>?

    init(
        appAttestService: some AppAttestService,
        deviceRegistrationClient: some DeviceRegistrationClient,
        sessionTokensRepository: some SessionTokensRepository,
        deviceRegistrationStatusRepository: some DeviceRegistrationStatusRepository,
        deviceKeyManager: DeviceKeyManager,
        nonceDecryptor: some NonceDecryptor,
        deviceMetadataProvider: @escaping @autoclosure () -> DeviceMetadata
    ) {
        self.appAttestService = appAttestService
        self.deviceRegistrationClient = deviceRegistrationClient
        self.sessionTokensRepository = sessionTokensRepository
        self.deviceRegistrationStatusRepository = deviceRegistrationStatusRepository

        self.deviceKeyManager = deviceKeyManager
        self.nonceDecryptor = nonceDecryptor

        deviceMetadata = deviceMetadataProvider()
    }

    /// Registers this device with the backend, if it hasn't been already.
    ///
    /// - Returns: The freshly issued ``SessionTokens`` when this call actually registered the device.
    /// `nil` when the device was already registered.
    /// Obtain a session separately (e.g. via ``RenewSessionTokensUseCase``) if needed.
    public func callAsFunction() async throws(RegisterDeviceError) -> SessionTokens? {
        if deviceRegistrationStatusRepository.retrieve() {
            return nil
        }

        if let inFlightRegistrationTask {
            return try await inFlightRegistrationTask.value.get()
        }

        let task: Task<Result<SessionTokens?, RegisterDeviceError>, Never> = Task {
            do throws(RegisterDeviceError) {
                return .success(try await register())
            } catch {
                deviceRegistrationStatusRepository.persist(isRegistered: false)
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

        let sessionTokens = try await registerDevice(
            devicePublicKey: devicePublicKey,
            decryptedNonce: decryptedNonce,
            signature: signature,
            attestationToken: attestationToken
        )

        if let sessionTokens {
            try await persist(sessionTokens: sessionTokens)
        }
        deviceRegistrationStatusRepository.persist(isRegistered: true)

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
            return try await deviceRegistrationClient.requestCipheredNonce(devicePublicKey: devicePublicKey)
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

    private func registerDevice(
        devicePublicKey: DevicePublicKey,
        decryptedNonce: String,
        signature: DeviceSignature,
        attestationToken: Data?
    ) async throws(RegisterDeviceError) -> SessionTokens? {
        do {
            return try await deviceRegistrationClient.register(
                devicePublicKey: devicePublicKey,
                decryptedNonce: decryptedNonce,
                metadata: deviceMetadata,
                signature: signature,
                attestationToken: attestationToken
            )
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
