//
//  RippleEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import CryptoSwift

class RippleEngine: CardEngine {
    
    var card: Card
    
    var walletType: WalletType {
        return .ripple
    }
    
    var walletUnits: String {
        return "XRP"
    }
    
    var qrCodePreffix: String {
        return "ripple:"
    }
    
    var walletAddress: String = ""
    var exploreLink: String {
        return "https://xrpscan.com/account/" + walletAddress
    }
    
    required init(card: Card) {
        self.card = card
        
        setupAddress()
    }
    
    func setupAddress() {
        var canonicalPubKey: [UInt8]
        
        switch card.curveID {
        case .secp256k1:
            let vrfy: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_NONE)!
            var pubkey = secp256k1_pubkey()
            _ = secp256k1_ec_pubkey_parse(vrfy, &pubkey, card.walletPublicKeyBytesArray, 65)
            
            var pubLength: UInt = 33
            var pubKeyCompressed = Array(repeating: 0, count: Int(pubLength)) as [UInt8]
            _ = secp256k1_ec_pubkey_serialize(vrfy, &pubKeyCompressed, &pubLength, pubkey, SECP256K1_FLAGS.SECP256K1_EC_COMPRESSED)
            canonicalPubKey = pubKeyCompressed 
        case .ed25519:
            canonicalPubKey = [0xED] + card.walletPublicKeyBytesArray
        }
        
        guard canonicalPubKey.count == 33 else {
            assertionFailure()
            return
        }
        
        guard let forRIPEMD160 = sha256(dataWithHexString(hex: canonicalPubKey.toHexString())) else {
            assertionFailure()
            return
        }
        
        let input = RIPEMD160.hash(message: forRIPEMD160).bytes

        let buffer = [0x00] + input 
        let checkSum = Array(buffer.sha256().sha256()[0..<4])
        
        walletAddress = String(base58Encoding: Data(bytes: buffer + checkSum), alphabet: Base58String.xrpAlphabet)
        
        card.blockchainDisplayName = "Ripple"
        card.node = "explorer2.adalite.io"
    }
    
}
