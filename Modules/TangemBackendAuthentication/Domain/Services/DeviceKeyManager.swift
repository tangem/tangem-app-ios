//
//  DeviceKeyManager.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.Data
private import enum CryptoKit.P256

/// Provides the device's P-256 (secp256r1) public key and signs data with its private counterpart, for backend authentication:
/// - device registration
/// - authentication
/// - DPoP-proofed requests.
///
/// - Invariant: The private key data itself never leaves this type.
/// ``publicKey`` only ever exposes its public counterpart, and ``sign(data:)`` is the only way to use it.
public actor DeviceKeyManager {
    private let privateKeyRepository: any DevicePrivateKeyRepository
    private var generateOrLoadPrivateKeyTask: Task<Result<any DevicePrivateKey, DevicePrivateKeyRepositoryError>, Never>?

    init(privateKeyRepository: some DevicePrivateKeyRepository) {
        self.privateKeyRepository = privateKeyRepository
        generateOrLoadPrivateKeyTask = Task { @concurrent in
            do throws(DevicePrivateKeyRepositoryError) {
                return Result.success(try await privateKeyRepository.retrieve())
            } catch {
                return Result.failure(error)
            }
        }
    }

    /// The device's public key.
    ///
    /// - Note: Cheap to access repeatedly — deriving it from the private key is measured at sub-microsecond.
    /// `async throws` because the very first access may have to wait on the private key itself becoming available.
    /// Secure Enclave key generation or restoration may take tens of milliseconds.
    public var publicKey: DevicePublicKey {
        get async throws(DeviceKeyManagerError) {
            let privateKey = try await resolvePrivateKey()

            do {
                return try privateKey.publicKey
            } catch {
                throw DeviceKeyManagerError.publicKeyConstructionFailed(error)
            }
        }
    }

    /// Signs `data` with the device's private key.
    ///
    /// - Note: Unlike ``publicKey``, this isn't cheap:
    /// every call performs a real Secure Enclave signing operation (measured at ~5ms on real hardware).
    /// Avoid calling it more often than the backend contract requires.
    @concurrent
    public func sign(data: Data) async throws(DeviceKeyManagerError) -> DeviceSignature {
        let privateKey = try await resolvePrivateKey()

        let signature: P256.Signing.ECDSASignature
        do {
            signature = try privateKey.signature(for: data)
        } catch {
            throw DeviceKeyManagerError.signingFailed(underlying: error)
        }

        do {
            return try DeviceSignature(derRepresentation: signature.derRepresentation, rawRepresentation: signature.rawRepresentation)
        } catch {
            assertionFailure(
                "DeviceSignature is expected to be constructible by CryptoKit's P-256 ECDSASignature correctly. Developer mistake."
            )
            throw DeviceKeyManagerError.signingFailed(underlying: error)
        }
    }

    private func resolvePrivateKey() async throws(DeviceKeyManagerError) -> any DevicePrivateKey {
        let task: Task<Result<any DevicePrivateKey, DevicePrivateKeyRepositoryError>, Never>

        if let generateOrLoadPrivateKeyTask {
            task = generateOrLoadPrivateKeyTask
        } else {
            let privateKeyRepository = privateKeyRepository
            task = Task { @concurrent in
                do throws(DevicePrivateKeyRepositoryError) {
                    return Result.success(try await privateKeyRepository.retrieve())
                } catch {
                    return Result.failure(error)
                }
            }
            generateOrLoadPrivateKeyTask = task
        }

        switch await task.value {
        case .success(let privateKey):
            return privateKey

        case .failure(let error):
            generateOrLoadPrivateKeyTask = nil
            throw DeviceKeyManagerError.privateKeyUnavailable(error)
        }
    }
}
