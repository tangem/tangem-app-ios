//
//  TokenEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class TokenEngine: ETHEngine {
    
    override var walletType: WalletType {
        switch card.tokenSymbol {
        case "SEED":
            return .seed
        case "QLEAR":
            return .qlear
        case "CLE":
            return .cle
        case "ERT":
            return .ert
        case "WRL":
            return .wrl
        default:
            return .eth
        }
    }
    
    override var walletUnits: String {
        return card.tokenSymbol ?? "ETH"
    }
    
    override var exploreLink: String {
        guard let tokenContractAddress = card.tokenContractAddress else {
            return super.exploreLink
        }
        
        return "https://etherscan.io/token/\(tokenContractAddress)?a=\(walletAddress)"
    }
    
}
