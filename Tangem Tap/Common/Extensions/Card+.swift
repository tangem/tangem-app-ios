//
//  Card+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk

#if !CLIP
import BlockchainSdk
#endif

struct LegacyCardData {
    let isReusable: Bool
    let isTwin: Bool
    let isStart2Coin: Bool
    
    let blockchainName: String
    
    let tokenSymbol: String?
    let tokenContractAddress: String?
    let tokenDecimal: Int?
}

fileprivate struct ProductionInfo {
    static let shared = ProductionInfo()
    
    //all twins productMask
    //all cards with permanent wallet
    //sc2 issuerName "start2coin"
    //all !isreusable cards
    
    //blockchainName and curve?
    //tokenSymbol
    //tokenContractAddress
    //tokenDecimal
    
    //All batches of:
    //"TTM BANK"
    //productmask != note and twin
    
    func isTwinCard(_ batchId: String) -> Bool {
       return false
    }
    
    func isStar2Coin(_ batchId: String) -> Bool {
       return false
    }
    
    func defaultToken(_ batchId: String) -> Token? {
       return nil
    }
    
    func defaultBlockchain(_ batchId: String) -> Blockchain? {
       return nil
    }
    
    func isV3WithNotReusableWallet(_ batchId: String) -> Bool {
       return false
    }
}

extension Card {
    var canSign: Bool {
//        let isPin2Default = self.isPin2Default ?? true
//        let hasSmartSecurityDelay = settingsMask?.contains(.smartSecurityDelay) ?? false
//        let canSkipSD = hasSmartSecurityDelay && !isPin2Default
        
        if firmwareVersion.doubleValue < 2.28 {
            if settings.securityDelay > 1500 {
//                && !canSkipSD {
                return false
            }
        }
        
        return true
    }
    
    var isTwinCard: Bool {
        ProductionInfo.shared.isTwinCard(batchId)
    }
    
    
    var twinNumber: Int {
        TwinCardSeries.series(for: cardId)?.number ?? 0
    }
    
    
    var isStart2Coin: Bool {
        ProductionInfo.shared.isStar2Coin(batchId)
    }
    
    var isMultiWallet: Bool {
        if isTwinCard {
            return false
        }
        
        if isStart2Coin {
            return false
        }
        
        if firmwareVersion.major < 4,
           !supportedCurves.contains(.secp256k1) {
            return false
        }
        
        return true
    }
    
    var isPermanentLegacyWallet: Bool {
        if firmwareVersion < .multiwalletAvailable {
            return settings.isPermanentWallet
        }
        
        return false
    }
    
    var isNotReusableLegacyWallet: Bool {
        if firmwareVersion < .multiwalletAvailable {
            return ProductionInfo.shared.isV3WithNotReusableWallet(batchId)
        }
        
        return false
    }
    
    var walletSignedHashes: Int {
        wallets.compactMap { $0.totalSignedHashes }.reduce(0, +)
    }
    
    public var isTestnet: Bool {
        if firmwareVersion < .multiwalletAvailable {
            return ProductionInfo.shared.defaultBlockchain(batchId)?.isTestnet ?? false
        }
        
        if batchId == "99FF" { // ??
            return cardId.starts(with: batchId.reversed())
        }
       
        return false
    }
    
    public var defaultBlockchain: Blockchain? {
        if firmwareVersion < .multiwalletAvailable {
            return nil
        }
        
        return ProductionInfo.shared.defaultBlockchain(batchId)
    }
    
    public var defaultToken: Token? {
        if firmwareVersion < .multiwalletAvailable {
            return nil
        }
        
        return ProductionInfo.shared.defaultToken(batchId)
    }
    
    public var walletCurves: [EllipticCurve] {
        wallets.compactMap { $0.curve }
    }
}
