//
//  PrepareUserWalletRegistrationUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import struct Foundation.Data
public import TangemFoundation

public struct PrepareUserWalletRegistrationUseCase: Sendable {
    typealias RegisterDevice = @Sendable () async throws(RegisterDeviceError) -> SessionTokens?

    private let registerDevice: RegisterDevice

    private let appAttestService: any AppAttestService
    private let registrationClient: any UserWalletRegistrationClient
    private let registrationStatusRepository: any UserWalletRegistrationStatusRepository

    private let deviceKeyManager: DeviceKeyManager
    private let nonceDecryptor: any NonceDecryptor

    private let deviceMetadataProvider: @Sendable () -> DeviceMetadata

    init(
        registerDevice: @escaping RegisterDevice,
        appAttestService: some AppAttestService,
        registrationClient: some UserWalletRegistrationClient,
        registrationStatusRepository: some UserWalletRegistrationStatusRepository,
        deviceKeyManager: DeviceKeyManager,
        nonceDecryptor: some NonceDecryptor,
        deviceMetadataProvider: @escaping @Sendable @autoclosure () -> DeviceMetadata
    ) {
        self.registerDevice = registerDevice
        self.appAttestService = appAttestService
        self.registrationClient = registrationClient
        self.registrationStatusRepository = registrationStatusRepository
        self.deviceKeyManager = deviceKeyManager
        self.nonceDecryptor = nonceDecryptor
        self.deviceMetadataProvider = deviceMetadataProvider
    }

    public func callAsFunction(
        id: UserWalletId,
        signer: some UserWalletRegistrationSigner
    ) async throws(PrepareUserWalletRegistrationError) -> UserWalletRegistrationRequest? {
        let userWalletIsAlreadyRegistered = await registrationStatusRepository.retrieve(id: id)

        guard !userWalletIsAlreadyRegistered else { return nil }

        try await ensureDeviceIsRegistered()

        let devicePublicKey = try await resolveDevicePublicKey()
        let cipheredNonce = try await requestCipheredNonce(for: devicePublicKey)

        let decryptedNonceBytes = try decrypt(cipheredNonce: cipheredNonce)
        let decryptedNonce = String(decoding: decryptedNonceBytes, as: UTF8.self)
        let nonceBytesToSign = try decodeNonceForSigning(decryptedNonce)

        async let attestationTokenTask = generateAttestationToken(for: decryptedNonceBytes)
        async let attestationTask = generateUserWalletAttestation(signer: signer, decryptedNonceBytes: nonceBytesToSign)

        let attestationToken = await attestationTokenTask
        let attestation = try await attestationTask.get()

        return UserWalletRegistrationRequest(
            id: id,
            attestation: attestation,
            decryptedNonce: decryptedNonce,
            appAttestationToken: attestationToken,
            metadata: deviceMetadataProvider()
        )
    }

    private func ensureDeviceIsRegistered() async throws(PrepareUserWalletRegistrationError) {
        do {
            _ = try await registerDevice()
        } catch {
            throw PrepareUserWalletRegistrationError.deviceRegistrationFailure(error)
        }
    }

    private func resolveDevicePublicKey() async throws(PrepareUserWalletRegistrationError) -> DevicePublicKey {
        do {
            return try await deviceKeyManager.publicKey
        } catch {
            throw PrepareUserWalletRegistrationError.deviceKeyFailure(error)
        }
    }

    private func requestCipheredNonce(
        for devicePublicKey: DevicePublicKey
    ) async throws(PrepareUserWalletRegistrationError) -> String {
        do {
            return try await registrationClient.requestCipheredNonce(devicePublicKey: devicePublicKey)
        } catch {
            throw PrepareUserWalletRegistrationError.clientFailure(error)
        }
    }

    private func decrypt(cipheredNonce: String) throws(PrepareUserWalletRegistrationError) -> Data {
        do {
            return try nonceDecryptor.decrypt(cipheredNonce: cipheredNonce)
        } catch {
            throw PrepareUserWalletRegistrationError.nonceDecryptionFailure(error)
        }
    }

    private func decodeNonceForSigning(_ decryptedNonce: String) throws(PrepareUserWalletRegistrationError) -> Data {
        guard let nonceBytesToSign = decryptedNonce.base64URLDecodedData() else {
            throw PrepareUserWalletRegistrationError.invalidDecryptedNonceEncoding
        }
        return nonceBytesToSign
    }

    private func generateAttestationToken(for decryptedNonceBytes: Data) async -> Data? {
        do {
            return try await appAttestService.generateAttestationToken(for: decryptedNonceBytes)
        } catch {
            // [REDACTED_TODO_COMMENT]
            return nil
        }
    }

    private func generateUserWalletAttestation(
        signer: some UserWalletRegistrationSigner,
        decryptedNonceBytes: Data
    ) async -> Result<UserWalletAttestation, PrepareUserWalletRegistrationError> {
        do {
            return Result.success(try await signer.attest(decryptedNonceBytes: decryptedNonceBytes))
        } catch {
            return Result.failure(PrepareUserWalletRegistrationError.signerFailure(error))
        }
    }
}
