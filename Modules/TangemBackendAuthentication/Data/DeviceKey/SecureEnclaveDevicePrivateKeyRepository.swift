//
//  SecureEnclaveDevicePrivateKeyRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import enum CryptoKit.SecureEnclave
private import Foundation
private import Security

struct SecureEnclaveDevicePrivateKeyRepository: DevicePrivateKeyRepository {
    private let keychainRepository: any KeychainRepository

    init(keychainRepository: some KeychainRepository) {
        precondition(SecureEnclave.isAvailable)
        self.keychainRepository = keychainRepository
    }

    func retrieve() async throws(DevicePrivateKeyRepositoryError) -> SecureEnclaveDevicePrivateKey {
        let privateKey: SecureEnclave.P256.Signing.PrivateKey

        if let existingKey = try await loadFromKeychain() {
            privateKey = existingKey
        } else {
            privateKey = try await generateAndStoreInKeychain()
        }

        return SecureEnclaveDevicePrivateKey(key: privateKey)
    }

    func delete() async throws(DevicePrivateKeyRepositoryError) {
        do {
            try await keychainRepository.delete()
        } catch {
            throw DevicePrivateKeyRepositoryError.keychainFailure(error)
        }
    }

    private func loadFromKeychain() async throws(DevicePrivateKeyRepositoryError) -> SecureEnclave.P256.Signing.PrivateKey? {
        let privateKeyDataRepresentation: Data?

        do {
            privateKeyDataRepresentation = try await keychainRepository.retrieve()
        } catch {
            throw DevicePrivateKeyRepositoryError.keychainFailure(error)
        }

        guard let privateKeyDataRepresentation else { return nil }

        do {
            return try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: privateKeyDataRepresentation)
        } catch {
            throw DevicePrivateKeyRepositoryError.keyRestorationFailed(underlying: error)
        }
    }

    private func generateAndStoreInKeychain() async throws(DevicePrivateKeyRepositoryError) -> SecureEnclave.P256.Signing.PrivateKey {
        let privateKey: SecureEnclave.P256.Signing.PrivateKey = try await Self.generateKey()

        do {
            try await keychainRepository.insert(privateKey.dataRepresentation)
        } catch {
            throw DevicePrivateKeyRepositoryError.keychainFailure(error)
        }

        return privateKey
    }

    @concurrent
    private static func generateKey() async throws(DevicePrivateKeyRepositoryError) -> SecureEnclave.P256.Signing.PrivateKey {
        var accessControlError: Unmanaged<CFError>?

        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage,
            &accessControlError
        ) else {
            throw DevicePrivateKeyRepositoryError.keyGenerationFailed(
                underlying: accessControlError!.takeRetainedValue() as any Error
            )
        }

        let privateKey: SecureEnclave.P256.Signing.PrivateKey

        do {
            privateKey = try SecureEnclave.P256.Signing.PrivateKey(accessControl: accessControl)
        } catch {
            throw DevicePrivateKeyRepositoryError.keyGenerationFailed(underlying: error)
        }

        return privateKey
    }
}
