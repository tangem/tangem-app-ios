//
//  TokenEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class TokenEngine: ETHEngine {
    override var payIdManager: PayIdManager? {
        if walletType == .nft {
            return nil
        } else {
            return super.payIdManager
        }
    }
    
    override var walletType: WalletType {
        
        if let symbol = card.tokenSymbol, symbol.containsIgnoringCase(find: "NFT:"){
            return .nft
        }
        
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
        case "USDC":
            return .usdc
        case "DGX":
            return .dgx
        case "AWG":
            return .awg
        default:
            return .eth
        }
    }
    
    public override var blockchainDisplayName: String {
        if walletType == .nft {
            return
                """
                Tangem TAG
                Ethereum non-fungible token
                """
        } else {
            return "Ethereum smart contract token"
        }
    }
    
    override var walletUnits: String {
        return "ETH"
    }
    
    override var exploreLink: String {
        guard let tokenContractAddress = card.tokenContractAddress else {
            return super.exploreLink
        }
        
        return "https://etherscan.io/token/\(tokenContractAddress)?a=\(walletAddress)"
    }
    
}
