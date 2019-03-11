//
//  ETHEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class ETHEngine: CardEngine {
    
    var card: Card
    
    var walletType: WalletType {
        return .eth
    }
    
    var walletUnits: String {
        return "ETH"
    }
    
    var walletAddress: String = ""
    var exploreLink: String {
        return "https://etherscan.io/address/" + walletAddress
    }
    
    required init(card: Card) {
        self.card = card
        
        setupAddress()
    }
    
    func setupAddress() {
        let hexPublicKey = card.walletPublicKey
        let hexPublicKeyWithoutTwoFirstLetters = String(hexPublicKey[hexPublicKey.index(hexPublicKey.startIndex, offsetBy: 2)...])
        let binaryCuttPublicKey = dataWithHexString(hex: hexPublicKeyWithoutTwoFirstLetters)
        let keccak = binaryCuttPublicKey.sha3(.keccak256)
        let hexKeccak = keccak.hexEncodedString()
        let cutHexKeccak = String(hexKeccak[hexKeccak.index(hexKeccak.startIndex, offsetBy: 24)...])
        
        walletAddress = "0x" + cutHexKeccak
        
        card.node = "mainnet.infura.io"
        card.blockchainDisplayName = "Ethereum"
    }
    
}
