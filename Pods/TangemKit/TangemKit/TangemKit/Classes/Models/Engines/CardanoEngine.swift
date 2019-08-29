//
//  CardanoEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftCBOR
import CryptoSwift
import Sodium

class CardanoEngine: CardEngine {
    
    var card: Card
    
    var blockchainDisplayName: String {
        return "Cardano"
    }
    
    var walletType: WalletType {
        return .cardano
    }
    
    var walletUnits: String {
        return "ADA"
    }
    
    var qrCodePreffix: String {
        return ""
    }
    
    var walletAddress: String = ""
    var exploreLink: String {
        return "https://cardanoexplorer.com/address/" + walletAddress
    }
    
    required init(card: Card) {
        self.card = card
        
        setupAddress()
    }
    
    func setupAddress() {
        let hexPublicKeyExtended = card.walletPublicKeyBytesArray + Array(repeating: 0, count: 32) 
        
        let forSha3 = ([0, [0, CBOR.byteString(hexPublicKeyExtended)], [:]] as CBOR).encode()
        
        let sha = forSha3.sha3(.sha256)
        let pkHash = Sodium().genericHash.hash(message: sha, outputLength: 28)!
        
        let addr = ([CBOR.byteString(pkHash), [:], 0] as CBOR).encode()
        let checksum = UInt64(addr.crc32())
        
        let addrItem = CBOR.tagged(CBOR.Tag(rawValue: 24), CBOR.byteString(addr)) 
        
        let hexAddress = ([addrItem, CBOR.unsignedInt(checksum)] as CBOR).encode()
        
        walletAddress = String(base58Encoding: Data(bytes: hexAddress))
        
        card.node = "explorer2.adalite.io"
    }
    
}
