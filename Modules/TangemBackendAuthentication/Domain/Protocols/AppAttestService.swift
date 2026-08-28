//
//  AppAttestService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

protocol AppAttestService: Sendable {
    func generateAttestationToken(for requestData: Data) async throws(AppAttestServiceError) -> Data
}
