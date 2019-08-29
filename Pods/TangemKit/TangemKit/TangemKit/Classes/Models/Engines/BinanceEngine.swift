//
//  BinanceEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class BinanceEngine: CardEngine {
    
    var card: Card
    
    var blockchainDisplayName: String {
        return "Binance"
    }
    
    var walletType: WalletType {
        return .binance 
    }
    
    var walletUnits: String {
        return "BNB"
    }
    
    var qrCodePreffix: String {
        return ""
    }
    
    var walletAddress: String = ""
    var exploreLink: String {
        return "https://explorer.binance.org/address/" + walletAddress
    }
    
    required init(card: Card) {
        self.card = card
        
        setupAddress()
    }
    
    func setupAddress() {
        guard let forRIPEMD160 = sha256(dataWithHexString(hex: pubKeyCompressed.toHexString())) else {
            assertionFailure()
            return
        }
        
        let pubKeyHash = RIPEMD160.hash(message: forRIPEMD160) 
        
        if card.isTestBlockchain {
            walletAddress = Bech32().encode("tbnb", values: pubKeyHash)
            card.node = "testnet-dex.binance.org/"
        } else {
            walletAddress = Bech32().encode("bnb", values: pubKeyHash)
            card.node = "dex.binance.org/"
        }
        
        

    }
    
    
}
