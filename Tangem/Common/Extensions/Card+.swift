//
//  Card+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk

#if !CLIP
import struct BlockchainSdk.Token
import enum BlockchainSdk.Blockchain
#endif

extension Card {
    var canSign: Bool {
//        let isPin2Default = self.isPin2Default ?? true
//        let hasSmartSecurityDelay = settingsMask?.contains(.smartSecurityDelay) ?? false
//        let canSkipSD = hasSmartSecurityDelay && !isPin2Default
        
        if firmwareVersion.doubleValue < 2.28 {
            if settings.securityDelay > 15000 {
//                && !canSkipSD {
                return false
            }
        }
        
        return true
    }
    
    var isTwinCard: Bool {
        TwinCardSeries.series(for: cardId) != nil
    }
    
    
    var twinNumber: Int {
        TwinCardSeries.series(for: cardId)?.number ?? 0
    }
    
    
    var isStart2Coin: Bool {
        issuer.name.lowercased() == "start2coin"
    }
    
    var isDemoCard: Bool {
        switch cardId {
        case "FB01000000000148": //Note BTC / AB01
            fallthrough
        case "FF02000000000139": //Note ETH / Batch AB02
            fallthrough
        case "FF03000000000153": //Wallet  / Batch AC01
            return true
        default:
            return false
        }
    }
    
    var isPermanentLegacyWallet: Bool {
        if firmwareVersion < .multiwalletAvailable {
            return wallets.first?.settings.isPermanent ?? false
        }
        
        return false
    }
    
    var walletSignedHashes: Int {
        wallets.compactMap { $0.totalSignedHashes }.reduce(0, +)
    }
    
    public var walletCurves: [EllipticCurve] {
        wallets.compactMap { $0.curve }
    }
}
