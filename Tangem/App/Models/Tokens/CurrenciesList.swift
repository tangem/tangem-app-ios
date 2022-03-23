//
//  CurrenciesList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct CurrenciesList: Codable {
    let imageHost: URL?
    let tokens: [CurrencyEntity]
}

struct CurrencyEntity: Codable {
    public let id: String
    public let name: String
    public let symbol: String
    public let contracts: [ContractEntity]?
}

struct ContractEntity: Codable {
    public let networkId: String
    public let address: String
    public let decimalCount: Int
}
