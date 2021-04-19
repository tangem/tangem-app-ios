//
//  Card+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk
import BlockchainSdk

extension Card {
    var canSign: Bool {
//        let isPin2Default = self.isPin2Default ?? true
//        let hasSmartSecurityDelay = settingsMask?.contains(.smartSecurityDelay) ?? false
//        let canSkipSD = hasSmartSecurityDelay && !isPin2Default
        
        if let fw = firmwareVersionValue, fw < 2.28 {
            if let securityDelay = pauseBeforePin2, securityDelay > 1500 {
//                && !canSkipSD {
                return false
            }
        }
        
        return true
    }
    
        var cardValidationData: (cid: String, pubKey: String)? {
        guard
            let cid = cardId,
            let pubKey = cardPublicKey?.asHexString()
        else { return nil }
        
        return (cid, pubKey)
    }
    
    var isStart2Coin: Bool {
        if let issuerName = cardData?.issuerName,
           issuerName.lowercased() == "start2coin" {
            return true
        }
        return false
    }
    
    var isMultiWallet: Bool {
        if isTwinCard {
            return false
        }
        
        if isStart2Coin {
            return false
        }
        
        if let major = firmwareVersion?.major, major < 4,
           !walletCurves.contains(.secp256k1) {
            return false
        }
        
        return true
    }
    
    public var defaultBlockchain: Blockchain? {
        guard let major = firmwareVersion?.major, major < 4 else {
            return nil
        }
        
        
        if let name = cardData?.blockchainName,
           let curve = walletCurves.first {
            return Blockchain.from(blockchainName: name, curve: curve)
        }
        return nil
    }
    
    public var isTestnet: Bool? {
        guard let major = firmwareVersion?.major, major < 4 else {
            return nil
        }
        
        return defaultBlockchain?.isTestnet
    }
    
    public var defaultToken: Token? {
        guard let major = firmwareVersion?.major, major < 4 else {
            return nil
        }
        
        if let symbol = cardData?.tokenSymbol,
           let contractAddress = cardData?.tokenContractAddress,
           let decimal = cardData?.tokenDecimal {
            return Token(symbol: symbol,
                         contractAddress: contractAddress,
                         decimalCount: decimal)
        }
        return nil
    }
    
    public var walletCurves: [EllipticCurve] {
        wallets.compactMap { $0.curve }
    }
}

