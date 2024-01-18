//
//  ExpressExchangeDataDecoder.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressExchangeDataDecoder {
    func decode(txDetailsJson: String, signature: String) throws -> DecodedTransactionDetails
}
