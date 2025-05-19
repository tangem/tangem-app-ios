//
//  WalletConnectDAppVerificationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL

protocol WalletConnectDAppVerificationService {
    func verify(dAppDomain: URL) async throws -> WalletConnectDAppVerificationStatus
}
