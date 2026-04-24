//
//  BlockBookTransactionHistoryTotalPageCountExtractor.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol BlockBookTransactionHistoryTotalPageCountExtractor {
    func extractTotalPageCount(from response: BlockBookAddressResponse, contractAddress: String?) throws -> Int
}
