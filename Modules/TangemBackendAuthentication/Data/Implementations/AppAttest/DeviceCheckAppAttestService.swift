//
//  DeviceCheckAppAttestService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import struct CryptoKit.SHA256
import DeviceCheck
import struct Foundation.Data
import struct TangemLogger.Logger

struct DeviceCheckAppAttestService: AppAttestService {
    private let appAttestService: DCAppAttestService
    private let keyIDRepository: any KeychainRepository

    private let analyticsReporter: any BackendAuthenticationAppAttestAnalyticsReporter
    private let logger: TangemLogger.Logger

    init(
        appAttestService: DCAppAttestService,
        keyIDRepository: some KeychainRepository,
        analyticsReporter: some BackendAuthenticationAppAttestAnalyticsReporter,
        logger: TangemLogger.Logger
    ) {
        Swift.assert(
            appAttestService.isSupported,
            """
            AppAttest DCAppAttestService is not supported on this device.\
            SimulatorAppAttestService is expected to be used for simulator.
            """
        )

        self.appAttestService = appAttestService
        self.keyIDRepository = keyIDRepository

        self.analyticsReporter = analyticsReporter
        self.logger = logger
    }

    func attest(decryptedNonceBytes: Data) async throws(AppAttestServiceError) -> AppAttestation {
        do {
            let keyID = try await generateKeyID()
            let attestationObject = try await attest(keyID: keyID, decryptedNonceBytes: decryptedNonceBytes)
            try await persist(keyID: keyID)
            return AppAttestation(keyID: keyID, object: attestationObject)
        } catch AppAttestServiceError.deviceCheckUnsupported {
            let message = "AppAttest DCAppAttestService is not supported on this device. Unexpected app attestation call."
            Swift.assertionFailure(message)
            logger.error(message, error: AppAttestServiceError.deviceCheckUnsupported)
            analyticsReporter.reportAttestationFailed(with: AppAttestServiceError.deviceCheckUnsupported)
            throw AppAttestServiceError.deviceCheckUnsupported
        } catch {
            analyticsReporter.reportAttestationFailed(with: error)
            throw error
        }
    }

    func assert(decryptedNonceBytes: Data) async throws(AppAttestServiceError) -> AppAssertion {
        do {
            let keyID = try await retrieveKeyID()
            let assertionObject = try await assert(keyID: keyID, decryptedNonceBytes: decryptedNonceBytes)
            return AppAssertion(keyID: keyID, object: assertionObject)
        } catch AppAttestServiceError.deviceCheckUnsupported {
            let message = "AppAttest DCAppAttestService is not supported on this device. Unexpected app assertion call."
            Swift.assertionFailure(message)
            logger.error(message, error: AppAttestServiceError.deviceCheckUnsupported)
            analyticsReporter.reportAssertionFailed(with: AppAttestServiceError.deviceCheckUnsupported)
            throw AppAttestServiceError.deviceCheckUnsupported
        } catch {
            analyticsReporter.reportAssertionFailed(with: error)
            throw error
        }
    }

    private func generateKeyID() async throws(AppAttestServiceError) -> String {
        do {
            logger.debug("AppAttest device key generation started")
            let keyID = try await appAttestService.generateKey()
            logger.debug("AppAttest device key generation succeeded")
            return keyID
        } catch DCError.featureUnsupported {
            throw AppAttestServiceError.deviceCheckUnsupported
        } catch {
            throw AppAttestServiceError.keyGenerationFailed(underlying: error)
        }
    }

    private func attest(keyID: String, decryptedNonceBytes: Data) async throws(AppAttestServiceError) -> Data {
        logger.debug("AppAttest attestation request to Apple started")

        let clientDataHash = Self.makeClientDataHash(from: decryptedNonceBytes)

        do {
            let attestationObject = try await appAttestService.attestKey(keyID, clientDataHash: clientDataHash)
            logger.debug("AppAttest attestation request to Apple succeeded")
            return attestationObject
        } catch DCError.featureUnsupported {
            throw AppAttestServiceError.deviceCheckUnsupported
        } catch DCError.serverUnavailable {
            throw AppAttestServiceError.attestationServerUnavailable
        } catch {
            throw AppAttestServiceError.attestationFailed(underlying: error)
        }
    }

    private func assert(keyID: String, decryptedNonceBytes: Data) async throws(AppAttestServiceError) -> Data {
        logger.debug("AppAttest assertion generation started")

        do {
            let clientDataHash = Self.makeClientDataHash(from: decryptedNonceBytes)
            let assertionObject = try await appAttestService.generateAssertion(keyID, clientDataHash: clientDataHash)
            logger.debug("AppAttest assertion generation succeeded")
            return assertionObject
        } catch DCError.featureUnsupported {
            throw AppAttestServiceError.deviceCheckUnsupported
        } catch DCError.invalidKey {
            await deleteKeyID()
            throw AppAttestServiceError.assertionKeyCorrupted
        } catch DCError.invalidInput {
            assertionFailure("Malformed keyID or clientDataHash. Developer mistake")
            throw AppAttestServiceError.assertionFailed(underlying: DCError(.invalidInput))
        } catch {
            throw AppAttestServiceError.assertionFailed(underlying: error)
        }
    }

    private func persist(keyID: String) async throws(AppAttestServiceError) {
        do {
            let keyIDBytes = Data(keyID.utf8)
            try await keyIDRepository.updateOrInsert(keyIDBytes)
        } catch {
            throw AppAttestServiceError.keychainFailure(error)
        }
    }

    private func deleteKeyID() async {
        do {
            try await keyIDRepository.delete()
        } catch {
            logger.error("AppAttest keyID removal failed", error: error)
        }
    }

    private func retrieveKeyID() async throws(AppAttestServiceError) -> String {
        let keyIDBytes: Data?

        do {
            keyIDBytes = try await keyIDRepository.retrieve()
        } catch {
            throw AppAttestServiceError.keychainFailure(error)
        }

        guard let keyIDBytes else {
            throw AppAttestServiceError.assertionKeyNotFound
        }

        guard let keyID = String(data: keyIDBytes, encoding: .utf8) else {
            await deleteKeyID()
            throw AppAttestServiceError.assertionKeyCorrupted
        }

        return keyID
    }

    private static func makeClientDataHash(from decryptedNonceBytes: Data) -> Data {
        let formattedNonceHashString = Data(SHA256.hash(data: decryptedNonceBytes)).base64EncodedString()
        return Data(SHA256.hash(data: Data(formattedNonceHashString.utf8)))
    }
}

extension DCAppAttestService: @retroactive @unchecked Sendable {}
