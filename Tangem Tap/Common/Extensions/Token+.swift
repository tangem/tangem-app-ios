//
//  Token+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

extension Token: Identifiable {
    public var id: Int { return hashValue }
    
    var color: Color {
        let hex = String(contractAddress.dropFirst(2).prefix(6)) + "FF"
        return Color(hex: hex) ?? Color.tangemTapGrayLight4
    }
    
    enum CodingKeys: String, CodingKey {
        case name, symbol, contractAddress, decimalCount, customIcon, customIconUrl, blockchain
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let blockchain = try container.decodeIfPresent(Blockchain.self, forKey: .blockchain) ?? .ethereum(testnet: false)
        let name = try container.decode(String.self, forKey: .name)
        let symbol = try container.decode(String.self, forKey: .symbol)
        let contractAddress = try container.decode(String.self, forKey: .contractAddress)
        let decimalCount = try container.decode(Int.self, forKey: .decimalCount)
        let customIconUrl = try container.decodeIfPresent(String.self, forKey: .customIconUrl)
        let customIcon = try container.decodeIfPresent(String.self, forKey: .customIcon)
        
        self.init(name: name, symbol: symbol, contractAddress: contractAddress, decimalCount: decimalCount, customIcon: customIcon, customIconUrl: customIconUrl, blockchain: blockchain)
    }
}
