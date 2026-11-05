//
//  SimulatorAppAttestService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if targetEnvironment(simulator)

import struct Foundation.Data

struct SimulatorAppAttestService: AppAttestService {
    func attest(decryptedNonceBytes: Data) async throws(AppAttestServiceError) -> AppAttestation {
        throw AppAttestServiceError.deviceCheckUnsupported
    }

    func assert(decryptedNonceBytes: Data) async throws(AppAttestServiceError) -> AppAssertion {
        throw AppAttestServiceError.deviceCheckUnsupported
    }
}

#endif
