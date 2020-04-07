//
//  EthereumNetwork.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

enum EthereumNetwork: Int {
    case mainnet = 1
    case rsk = 30
    
    var chainId: BigUInt { return BigUInt(self.rawValue) }
    
    var url: URL {
        switch self {
        case .mainnet:
            return URL(string: "https://mainnet.infura.io/v3/613a0b14833145968b1f656240c7d245")!
        case .rsk:
            return URL(string: "https://public-node.rsk.co/")!
        }
    }
}
