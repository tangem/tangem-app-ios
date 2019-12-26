//
//  BCHEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import BinanceChain

class BCHEngine: CardEngine {
    var card: Card
    
    var blockchainDisplayName: String { "Bitcoin Cash" }
    
    var walletType: WalletType { .bch }
    
    var walletUnits: String { "BCH" }
    
    var walletAddress: String = ""
    
    var qrCodePreffix: String = ""
    
    var exploreLink: String {
        return "https://bch.btc.com/" + walletAddress
    }
    
    required init(card: Card) {
        self.card = card
        if card.isWallet {
            setupAddress()
        }
        
      
    }
    
    func setupAddress() {
        let prefix = Data([UInt8(0x00)]) //public key hash
        let payload = RIPEMD160.hash(message: Data(pubKeyCompressed.sha256()))
        walletAddress = HDBech32.encode(prefix + payload, prefix: "bitcoincash")
    }

    func test(){
        
    }
    
}
