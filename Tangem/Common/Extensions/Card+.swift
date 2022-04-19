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
            "AC01000000013489",
            "AC01000000028610",
            "AC01000000028701",
            "AC01000000028578",
            "AC01000000027281",
            "AC01000000027216",
            "AC01000000028594",
            "AC01000000028602",
            "AC01000000028636",
            "AC01000000013968",
            "AC01000000027208",
            "AC01000000013471",
            "AC01000000028586",
            "AC01000000013703",
            "AC01000000028628",
            "AC01000000028693",
            "AC01000000028685",
            "AC01000000013950",
            "AC01000000013828",
            "AC01000000013497",
            "AC01000000013836",
            "AC01000000013505",

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
            "AB01000000059608",
            "AB01000000059574",
            "AB01000000016475",
            "AB01000000016483",
            "AB01000000016491",
            "AB01000000020709",
            "AB01000000020717",
            "AB01000000015550",
            "AB01000000015394",
            "AB01000000016079",
            "AB01000000016087",
            "AB01000000016095",
            "AB01000000020915",
            "AB01000000017184",
            "AB01000000020907",
            "AB01000000017192",
            "AB01000000016210",
            "AB01000000016111",
            "AB01000000016103",
            "AB01000000015766",
            "AB01000000015774",
            "AB01000000015782",
            "AB01000000022598",
            "AB01000000022580",
            
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
            "AB02000000019924",
            "AB02000000019932",
            "AB02000000022092",
            "AB02000000022282",
            "AB02000000023983",
            "AB02000000023439",
            "AB02000000020328",
            "AB02000000020310",
            "AB02000000021565",
            "AB02000000022357",
            "AB02000000023355",
            "AB02000000022324",
            "AB02000000022100",
            "AB02000000019999",
            "AB02000000020013",
            "AB02000000020005",
            "AB02000000020021",
            "AB02000000020039",
            "AB02000000020278",
            "AB02000000020252",
            "AB02000000018652",
            "AB02000000018561",
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
        Card.getDerivationStyle(for: batchId, isHdWalletAllowed: settings.isHDWalletAllowed)
    }
    
    static func getDerivationStyle(for batchId: String, isHdWalletAllowed: Bool) -> DerivationStyle {
        guard isHdWalletAllowed else {
            return .legacy
        }
        
        let batchId = batchId.uppercased()
        
        if BatchId.isDetached(batchId) {
            return .legacy
        }
        
        return .new
    }
    
#endif
}
