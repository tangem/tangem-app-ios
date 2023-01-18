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
        case v5 = "v5.0"
    }

    static let limitAPIBaseURL: URL = .init(string: "https://limit-orders.1inch.io/\(OneInchAPIVersion.v2.rawValue)/")!
    static let exchangeAPIBaseURL: URL = .init(string: "https://api-tangem.1inch.io/\(OneInchAPIVersion.v5.rawValue)/")!
}
