//
//  BlockaidWalletConnectDAppVerificationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL

final class BlockaidWalletConnectDAppVerificationService: WalletConnectDAppVerificationService {
    private let apiService: any BlockaidAPIService

    init(apiService: some BlockaidAPIService) {
        self.apiService = apiService
    }

    func verify(dAppDomain: URL) async throws -> WalletConnectDAppVerificationStatus {
        let apiResult = try await apiService.scanSite(url: dAppDomain)
        return BlockaidSiteScanMapper.mapToDomain(apiResult)
    }
}
