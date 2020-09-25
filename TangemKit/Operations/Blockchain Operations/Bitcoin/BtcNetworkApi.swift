//
//  BtcNetworkApi.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

enum BtcBackend {
    case blockcypher
    case blockchainInfo
    
    var nodeDescription: String {
        switch self {
        case .blockcypher:
            return "api.blockcypher.com"
        case .blockchainInfo:
            return "blockchain.info"
        }
    }
}
