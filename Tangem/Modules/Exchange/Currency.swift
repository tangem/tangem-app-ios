//
//  Currency.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct Currency {
    let contractAddress: String
    let blockchainNetwork: BlockchainNetwork

    var name: String?
    var symbol: String?
    var decimalCount: Int?
    var imageURL: URL?

    private(set) var amount: Decimal = 0

    var isToken: Bool {
        contractAddress != Constants.oneInchCoinContractAddress
    }

    init(contractAddress: String,
         blockchainNetwork: BlockchainNetwork,
         name: String? = nil,
         symbol: String? = nil,
         decimalCount: Int? = nil,
         imageURL: URL? = nil,
         amount: Decimal = 0) {
        self.contractAddress = contractAddress
        self.blockchainNetwork = blockchainNetwork
        self.name = name
        self.symbol = symbol
        self.decimalCount = decimalCount
        self.imageURL = imageURL
        self.amount = amount
    }

    init(amount: Decimal, blockchainNetwork: BlockchainNetwork) {
        self.contractAddress = ""
        self.blockchainNetwork = blockchainNetwork
        self.amount = amount
    }

    mutating func updateImageURL(_ imageURL: URL) {
        self.imageURL = imageURL
    }

    mutating func updateAmount(_ amount: Decimal) {
        self.amount = amount
    }
}
