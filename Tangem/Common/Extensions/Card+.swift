//
//  Card+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk

#if !CLIP
import BlockchainSdk
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
    
    var canSupportSolanaTokens: Bool {
        //[REDACTED_TODO_COMMENT]
        let fwVersion = firmwareVersion.doubleValue
        return fwVersion >= 4.52
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
            "AB01000000046530",
            "AB01000000046720",
            "AB01000000046746",
            "AB01000000046498",
            "AB01000000046753",
            "AB01000000049608",
            "AB01000000046761",
            "AB01000000049574",
            "AB01000000046605",
            "AB01000000046571",
            "AB01000000046704",
            "AB01000000046647",
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
    
    var walletCurves: [EllipticCurve] {
        wallets.compactMap { $0.curve }
    }
    
#if !CLIP
    var derivationStyle: DerivationStyle {
        let batchId = batchId.uppercased()
        
        if batchId == "AC01" || batchId == "AC02" {
            return .legacy
        }
        
        return .new
    }
#endif
}
