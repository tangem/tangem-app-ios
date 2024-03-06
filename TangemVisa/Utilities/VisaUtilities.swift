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
    public init() {}

    public var visaToken: Token {
        testnetUSDTtoken
    }

    public var visaBlockchain: Blockchain {
        .polygon(testnet: true)
    }
}

internal extension VisaUtilities {
    var registryAddress: String {
        "0x3f4ae01073d1a9d5a92315fe118e57d1cdec7c44"
    }
}

private extension VisaUtilities {
    private var testnetUSDTtoken: Token {
        .init(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0x1A826Dfe31421151b3E7F2e4887a00070999150f",
            decimalCount: 18,
            id: "tether"
        )
    }
}
