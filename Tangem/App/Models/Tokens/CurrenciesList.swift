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
    
    static let baseURL: URL = .init(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/")!
}

struct CurrencyEntity: Codable {
    public let id: String
    public let name: String
    public let symbol: String
    public let active: Bool?
    public let contracts: [ContractEntity]?
}

struct ContractEntity: Codable {
    public let networkId: String
    public let address: String
    public let decimalCount: Int?
    public let active: Bool?
}
