//
//  CollectiblesBuybackTransactionGenerator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CollectiblesBuybackTransactionGenerator {
    func generate(
        nftAddress: String,
        fromAddress: String,
        toAddress: String
    ) async throws -> CollectiblesBuybackTransaction
}
