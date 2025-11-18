//
//  BlockaidAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils
import BlockchainSdk
import ReownWalletKit

protocol BlockaidAPIService {
    func scanSite(url: URL) async throws -> BlockaidDTO.SiteScan.Response

    func scanEvm(
        address: String?,
        blockchain: BlockchainSdk.Blockchain,
        method: String,
        params: [AnyCodable],
        domain: URL
    ) async throws -> BlockaidDTO.EvmScan.Response

    func scanSolana(
        address: String,
        method: String,
        transactions: [String],
        domain: URL
    ) async throws -> BlockaidDTO.SolanaScan.Response

    func scanEvmTransactionBulk(
        blockchain: BlockchainSdk.Blockchain,
        transactions: [BlockaidDTO.TransactionParams]
    ) async throws -> BlockaidDTO.EvmTransactionBulkScan.Response
}
