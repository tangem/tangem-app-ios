//
//  RippleEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import CryptoSwift

public class RippleEngine: CardEngine {
    
    unowned public var card: CardViewModel
    
    public var blockchainDisplayName: String {
        return "Ripple"
    }
    
    public var walletReserve: String?
    public var walletType: WalletType {
        return .ripple
    }
    
    public var walletUnits: String {
        return "XRP"
    }
    
    public var qrCodePreffix: String {
        return "ripple:"
    }
    
    public var walletAddress: String = ""
    public var exploreLink: String {
        return "https://xrpscan.com/account/" + walletAddress
    }
    
    public required init(card: CardViewModel) {
        self.card = card
        if card.isWallet {
            setupAddress()
        }
    }
    
    public func setupAddress() {
        var canonicalPubKey: [UInt8]
        
        switch card.curveID {
        case .secp256k1:
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
        
        card.node = "explorer2.adalite.io"
    }
    
}
