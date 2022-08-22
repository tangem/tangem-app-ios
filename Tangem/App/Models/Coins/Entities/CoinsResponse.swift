//
//  CoinsResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct CoinsResponse: Codable {
    let total: Int
    let imageHost: URL?
    let coins: [CoinsResponse.Coin]

    static let baseURL: URL = .init(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/")!
}
