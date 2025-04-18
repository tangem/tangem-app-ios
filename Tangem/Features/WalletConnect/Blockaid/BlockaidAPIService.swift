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

protocol BlockaidAPIService {
    func scanSite(url: URL) async throws -> BlockaidDTO.SiteScan.Response

    func scanEvm(
        address: String?,
        blockchain: Blockchain,
        method: String,
        transaction: WalletConnectEthTransaction, // not sure whether this model will still be used
        domain: URL
    ) async throws -> BlockaidDTO.EvmScan.Response

    func scanSolana(
        address: String,
        method: String,
        transactions: [String],
        domain: URL
    ) async throws -> BlockaidDTO.SolanaScan.Response
}
