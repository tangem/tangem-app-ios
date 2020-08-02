//
//  CardEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

public enum WalletType {
    case btc
    case ltc
    case bch
    case eth
    case seed
    case cle
    case qlear
    case ert
    case wrl
    case rsk
    case cardano
    case ripple
    case nft
    case binance
    case empty
    case stellar
    case slix2
    case ducatus
    case usdc
    case dgx
    case awg
}

public protocol CardEngine: class {
    
    var card: CardViewModel { get set }
    var blockchainDisplayName: String { get }
    
    var walletType: WalletType { get }
    var walletUnits: String { get }
    var walletAddress: String { get }
    var qrCodePreffix: String { get }
    
    var exploreLink: String { get }
    
    init(card: CardViewModel)
    
    func setupAddress()
    
}

extension CardEngine {
    
    var pubKeyCompressed: [UInt8] {
        let vrfy: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_NONE)!
        var pubkey = secp256k1_pubkey()
        _ = secp256k1_ec_pubkey_parse(vrfy, &pubkey, card.walletPublicKeyBytesArray, 65)
        
        var pubLength: UInt = 33
        var pubKeyCompressed = Array(repeating: 0, count: Int(pubLength)) as [UInt8]
        _ = secp256k1_ec_pubkey_serialize(vrfy, &pubKeyCompressed, &pubLength, pubkey, SECP256K1_FLAGS.SECP256K1_EC_COMPRESSED)
        
        return pubKeyCompressed
    }
    
}

class NoWalletCardEngine: CardEngine {
    
    var card: CardViewModel
    
    var blockchainDisplayName: String {
        return "No blockchain"
    }
    
    var walletType: WalletType = .empty
    var walletUnits: String = "---"
    var walletAddress: String = ""
    var exploreLink: String {
        return ""
    }
    
    var qrCodePreffix: String {
        return ""
    }
    
    required init(card: CardViewModel) {
        self.card = card
    }
    
    func setupAddress() {

    }
    
}
