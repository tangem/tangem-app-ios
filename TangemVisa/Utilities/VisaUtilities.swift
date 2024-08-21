//
//  VisaUtilities.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct VisaUtilities {
    private let isTestnet: Bool

    public init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    public var tokenId: String {
        "tether"
    }

    public var mockToken: Token {
        .init(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0x1A826Dfe31421151b3E7F2e4887a00070999150f",
            decimalCount: 18,
            id: tokenId
        )
    }

    public var visaBlockchain: Blockchain {
        .polygon(testnet: isTestnet)
    }
}
