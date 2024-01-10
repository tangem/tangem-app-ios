//
//  TransactionSenderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSwapping
import BlockchainSdk

struct SwappingFeeFormatterMock: SwappingFeeFormatter {
    func format(fee: Decimal, tokenItem: TokenItem) -> String { "" }
}
