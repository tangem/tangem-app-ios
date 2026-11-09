//
//  ObtainRecoveryAppAssertionUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct TangemLogger.Logger

package struct ObtainRecoveryAppAssertionUseCase: Sendable {
    private let appAttestService: any AppAttestService
    private let appAttestationStatusRepository: any AppAttestationStatusRepository
    private let logger: Logger

    init(
        appAttestService: some AppAttestService,
        appAttestationStatusRepository: some AppAttestationStatusRepository,
        logger: Logger
    ) {
        self.appAttestService = appAttestService
        self.appAttestationStatusRepository = appAttestationStatusRepository
        self.logger = logger
    }

    package func callAsFunction(nonce: String) async -> AppAssertion? {
        let appHasAlreadyBeenAttested = appAttestationStatusRepository.retrieve()

        guard appHasAlreadyBeenAttested else {
            return nil
        }

        do {
            return try await appAttestService.assert(decryptedNonceBytes: Data(nonce.utf8))
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
}
