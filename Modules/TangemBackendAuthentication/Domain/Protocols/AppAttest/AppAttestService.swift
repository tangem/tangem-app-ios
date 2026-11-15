//
//  AppAttestService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

protocol AppAttestService: Sendable {
    func attest(decryptedNonceBytes: Data) async throws(AppAttestServiceError) -> AppAttestation
    func assert(decryptedNonceBytes: Data) async throws(AppAttestServiceError) -> AppAssertion
}
