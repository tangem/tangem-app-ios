//
//  ExchangeConstants.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum Constants {
    private enum OneInchAPIVersion: String {
        case v2 = "v2.0"
        case v4 = "v4.0"
        case v5 = "v5.0"
    }

    static let limitAPIBaseURL: URL = URL(string: "https://limit-orders.1inch.io/\(OneInchAPIVersion.v2.rawValue)/")!
//    static let exchangeAPIBaseURL: URL = URL(string: "https://api.1inch.io/\(OneInchAPIVersion.v4.rawValue)/")!
    static let exchangeAPIBaseURL: URL = URL(string: "https://api-tangem.1inch.io/\(OneInchAPIVersion.v5.rawValue)/")!
}
