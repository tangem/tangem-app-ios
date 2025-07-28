//
//  BlockaidWalletConnectDAppVerificationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import TangemLogger

final class BlockaidWalletConnectDAppVerificationService: WalletConnectDAppVerificationService {
    private let apiService: any BlockaidAPIService
    private let logger: TangemLogger.Logger

    init(apiService: some BlockaidAPIService, logger: TangemLogger.Logger) {
        self.apiService = apiService
        self.logger = logger
    }

    func verify(dAppDomain: URL) async throws -> WalletConnectDAppVerificationStatus {
        do {
            let apiResult = try await apiService.scanSite(url: dAppDomain)
            return BlockaidSiteScanMapper.mapToDomain(apiResult)
        } catch {
            logger.error("Blockaid site scan result failure", error: error)
            throw error
        }
    }
}
