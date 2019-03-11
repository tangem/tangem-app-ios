//
//  BTCEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class BTCEngine: CardEngine {
    
    var card: Card
    
    var walletType: WalletType {
        return .btc
    }

    var walletUnits: String {
        return "BTC"
    }
    
    var walletAddress: String = ""
    var exploreLink: String {
        return "https://blockchain.info/address/" + walletAddress
    }
    
    required init(card: Card) {
        self.card = card
        
        setupAddress()
    }
    
    func setupAddress() {
        let hexPublicKey = card.walletPublicKey
        
        let binaryPublicKey = dataWithHexString(hex: hexPublicKey)
        
        guard let binaryHash = sha256(binaryPublicKey) else {
            assertionFailure()
            return
        }
        
        let binaryRipemd160 = RIPEMD160.hash(message: binaryHash)
        
        let hexRipend160 = "00" + binaryRipemd160.hexEncodedString()
        
        let binaryExtendedRipemd = dataWithHexString(hex: hexRipend160)
        guard let binaryOneSha = sha256(binaryExtendedRipemd) else {
            assertionFailure()
            return
        }
        
        guard let binaryTwoSha = sha256(binaryOneSha) else {
            assertionFailure()
            return
        }
        
        let binaryTwoShaToHex = binaryTwoSha.hexEncodedString()
        let checkHex = String(binaryTwoShaToHex[..<binaryTwoShaToHex.index(binaryTwoShaToHex.startIndex, offsetBy: 8)])
        let addCheckToRipemd = hexRipend160 + checkHex
        
        let binaryForBase58 = dataWithHexString(hex: addCheckToRipemd)
        
        walletAddress = String(base58Encoding: binaryForBase58) 
        
        card.node = randomNode()
        card.blockchainDisplayName = "Bitcoin"
    }
    
}
