//
//  ObtainUserWalletRegistrationNonceUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import struct Foundation.Data
public import TangemFoundation
import struct TangemLogger.Logger

typealias ObtainUserWalletRegistrationNonce = @Sendable (
    _ id: UserWalletId
) async throws(ObtainUserWalletRegistrationNonceError) -> UserWalletRegistrationNonce?

public struct ObtainUserWalletRegistrationNonceUseCase: Sendable {
    private let registerDevice: RegisterDevice

    private let appAttestService: any AppAttestService
    private let registrationClient: any UserWalletRegistrationClient
    private let registrationStatusRepository: any UserWalletRegistrationStatusRepository

    private let deviceKeyManager: DeviceKeyManager
    private let nonceDecryptor: any NonceDecryptor

    private let logger: Logger

    init(
        registerDevice: @escaping RegisterDevice,
        appAttestService: some AppAttestService,
        registrationClient: some UserWalletRegistrationClient,
        registrationStatusRepository: some UserWalletRegistrationStatusRepository,
        deviceKeyManager: DeviceKeyManager,
        nonceDecryptor: some NonceDecryptor,
        logger: Logger
    ) {
        self.registerDevice = registerDevice
        self.appAttestService = appAttestService
        self.registrationClient = registrationClient
        self.registrationStatusRepository = registrationStatusRepository
        self.deviceKeyManager = deviceKeyManager
        self.nonceDecryptor = nonceDecryptor
        self.logger = logger
    }

    // [REDACTED_TODO_COMMENT]
    public func callAsFunction(
        id: UserWalletId?
    ) async throws(ObtainUserWalletRegistrationNonceError) -> UserWalletRegistrationNonce? {
        if let id, await registrationStatusRepository.retrieve(id: id) {
            return nil
        }

        try await ensureDeviceIsRegistered()

        let devicePublicKey = try await resolveDevicePublicKey()
        let cipheredNonce = try await requestCipheredNonce(for: devicePublicKey)

        let decryptedNonceBytes = try decrypt(cipheredNonce: cipheredNonce)
        let decryptedNonce = String(decoding: decryptedNonceBytes, as: UTF8.self)
        let nonceBytesToSign = try decodeNonceForSigning(decryptedNonce)

        let appAttestationToken = await generateAppAttestationToken(for: decryptedNonceBytes)

        return UserWalletRegistrationNonce(
            value: decryptedNonce,
            bytesToSign: nonceBytesToSign,
            appAttestationToken: appAttestationToken
        )
    }

    private func ensureDeviceIsRegistered() async throws(ObtainUserWalletRegistrationNonceError) {
        do {
            _ = try await registerDevice()
        } catch {
            throw ObtainUserWalletRegistrationNonceError.deviceRegistrationFailure(error)
        }
    }

    private func resolveDevicePublicKey() async throws(ObtainUserWalletRegistrationNonceError) -> DevicePublicKey {
        do {
            return try await deviceKeyManager.publicKey
        } catch {
            throw ObtainUserWalletRegistrationNonceError.deviceKeyFailure(error)
        }
    }

    private func requestCipheredNonce(
        for devicePublicKey: DevicePublicKey
    ) async throws(ObtainUserWalletRegistrationNonceError) -> String {
        do {
            return try await registrationClient.requestCipheredNonce(devicePublicKey: devicePublicKey)
        } catch {
            throw ObtainUserWalletRegistrationNonceError.clientFailure(error)
        }
    }

    private func decrypt(cipheredNonce: String) throws(ObtainUserWalletRegistrationNonceError) -> Data {
        do {
            return try nonceDecryptor.decrypt(cipheredNonce: cipheredNonce)
        } catch {
            throw ObtainUserWalletRegistrationNonceError.nonceDecryptionFailure(error)
        }
    }

    private func decodeNonceForSigning(
        _ decryptedNonce: String
    ) throws(ObtainUserWalletRegistrationNonceError) -> Data {
        guard let nonceBytesToSign = decryptedNonce.base64URLDecodedData() else {
            throw ObtainUserWalletRegistrationNonceError.invalidDecryptedNonceEncoding
        }
        return nonceBytesToSign
    }

    private func generateAppAttestationToken(for decryptedNonceBytes: Data) async -> Data? {
        do {
            return try await appAttestService.generateAttestationToken(for: decryptedNonceBytes)
        } catch {
            logger.error("Failed to generate app attestation token", error: error)
            return nil
        }
    }
}
