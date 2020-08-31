//
//  LTCEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation

class LTCEngine: BTCEngine {
    private let _payIdManager = PayIdManager(network: .LTC)
    override var payIdManager: PayIdManager? {
        return _payIdManager
    }
    
    override var relayFee: Decimal {
        Decimal(0.00001)
    }
    
    override var blockcyperApi: BlockcyperApi {
        .ltc
    }
    
    override var trait: CoinTrait {
        .allowsFeeInclude
    }
    
    override var possibleFirstAddressCharacters: [String] {
        return  ["l","m"]
    }
    
    override var blockchainDisplayName: String {
        return "Litecoin"
    }
    
    override var walletType: WalletType {
        return .ltc
    }
    
    override var walletUnits: String {
        return "LTC"
    }
    
    override var qrCodePreffix: String {
        return "litecoin:"
    }
    
    override var exploreLink: String {
        return "https://live.blockcypher.com/ltc/address/" + walletAddress
    }
    
    required init(card: CardViewModel) {
        super.init(card: card)
        currentBackend = .blockcypher
    }
    
    override func setupAddress() {
        let hash = Data(card.walletPublicKeyBytesArray.sha256())
        let ripemd160Hash = RIPEMD160.hash(message: hash)
        let netSelectionByte = Byte(0x30).asData
        let extendedRipemd160Hash = netSelectionByte + ripemd160Hash
        let sha = extendedRipemd160Hash.sha256().sha256()
        let ripemd160HashWithChecksum = extendedRipemd160Hash + sha[..<4]
        let base58 = String(base58Encoding: ripemd160HashWithChecksum, alphabet:Base58String.btcAlphabet)
        
        walletAddress = base58
        card.node = randomNode()
    }
    
    override func switchBackend() {
        
    }
}
