//
//  StubAppAttestService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
@testable import TangemBackendAuthentication

struct StubAppAttestService: AppAttestService {
    var result: Result<Data, AppAttestServiceError> = .success(Self.stubbedAttestationToken)

    func generateAttestationToken(for requestData: Data) async throws(AppAttestServiceError) -> Data {
        try result.get()
    }
}

extension StubAppAttestService {
    static let stubbedAttestationToken = Data("stubbed-attestation-token".utf8)
}
