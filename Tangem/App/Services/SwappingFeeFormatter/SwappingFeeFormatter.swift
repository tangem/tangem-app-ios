//
//  SwappingFeeFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSwapping

protocol SwappingFeeFormatter {
    func format(fee: Decimal, blockchain: SwappingBlockchain) async throws -> String
    func format(fee: Decimal, blockchain: SwappingBlockchain) throws -> String

    func format(fee: Decimal, tokenItem: TokenItem) -> String
}
