//
//  Currency.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.Blockchain

public struct Currency {
    public let networkId: String
    public let chainId: Int?
    public let name: String
    public let symbol: String
    public let decimalCount: Int
    public let imageURL: URL
    public let contractAddress: String?
    
    public var isToken: Bool {
        contractAddress != nil
    }
    
    init(
        networkId: String,
        chainId: Int?,
         name: String,
         symbol: String,
         decimalCount: Int,
         imageURL: URL,
         contractAddress: String? = nil
    ) {
        self.networkId = networkId
        self.chainId = chainId
        self.name = name
        self.symbol = symbol
        self.decimalCount = decimalCount
        self.imageURL = imageURL
        self.contractAddress = contractAddress
    }

//    init(amount: Decimal, blockchainNetwork: BlockchainNetwork) {
//        self.contractAddress = ""
//        self.blockchainNetwork = blockchainNetwork
//        self.amount = amount
//    }
//
//    mutating func updateImageURL(_ imageURL: URL) {
//        self.imageURL = imageURL
//    }
//
//    mutating func updateAmount(_ amount: Decimal) {
//        self.amount = amount
//    }
}
