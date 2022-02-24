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
        let demoCards: [String] = [
            "FB10000000000196", // Note BTC
            "FB20000000000186", // Note ETH
            "FB30000000000176", // Wallet
            "AB01000000045060", // Note BTC //[REDACTED_TODO_COMMENT]
            "AB02000000045028", // Note ETH //[REDACTED_TODO_COMMENT]
            "AC79000000000004", // Wallet 4.46 //[REDACTED_TODO_COMMENT]
            // Tangem Wallet:
            "AC01000000041100",
            "AC01000000042462",
            "AC01000000041647",
            "AC01000000041621",
            "AC01000000041217",
            "AC01000000041225",
            "AC01000000041209",
            "AC01000000041092",
            "AC01000000041472",
            "AC01000000041662",
            "AC01000000045754",
            "AC01000000045960",
            // Tangem Note BTC:
            "AB0100000046530",
            "AB0100000046720",
            "AB0100000046746",
            "AB0100000046498",
            "AB0100000046753",
            "AB0100000049608",
            "AB0100000046761",
            "AB0100000049574",
            "AB0100000046605",
            "AB0100000046571",
            "AB0100000046704",
            "AB0100000046647",
            // Tangem Note Ethereum:
            "AB02000000051000",
            "AB02000000050986",
            "AB02000000051026",
            "AB02000000051042",
            "AB02000000051091",
            "AB02000000051083",
            "AB02000000050960",
            "AB02000000051034",
            "AB02000000050911",
            "AB02000000051133",
            "AB02000000051158",
            "AB02000000051059",
        ]
        
        return demoCards.contains(cardId)
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
