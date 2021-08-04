//
//  Assembly+Preview.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
#if !CLIP
import BlockchainSdk
#endif

extension Assembly {
    enum PreviewCard {
        case withoutWallet, twin, ethereum, stellar, v4
        
        static func scanResult(for preview: PreviewCard, assembly: Assembly) -> ScanResult {
            let card = preview.card
            let ci = CardInfo(card: card,
                              walletData: preview.walletData,
                              artworkInfo: nil,
                              twinCardInfo: preview.twinInfo)
            let vm = assembly.makeCardModel(from: ci)
            let scanResult = ScanResult.card(model: vm)
            assembly.services.cardsRepository.cards[card.cardId] = scanResult
            return scanResult
        }
        
        var card: Card {
            switch self {
            case .withoutWallet: return .testCardNoWallet
            case .twin: return .testTwinCard
            case .ethereum: return .v4Card
            case .stellar: return .v4Card
            case .v4: return .v4Card
            }
        }
        
        var walletData: WalletData? {
            switch self {
            case .ethereum:
                return WalletData(blockchain: "ETH", token: nil)
            case .stellar:
                return WalletData(blockchain: "XLM", token: nil)
            default:
                return nil
            }
        }
        
        private var twinInfo: TwinCardInfo? {
            switch self {
            case .twin: return TwinCardInfo(cid: "CB64000000006522", series: .cb64, pairCid: "CB65000000006521", pairPublicKey: nil)
            default: return nil
            }
        }
    }
    
    static func previewAssembly(for card: PreviewCard) -> Assembly {
        let assembly = Assembly()
        
        assembly.services.cardsRepository.lastScanResult = PreviewCard.scanResult(for: card, assembly: assembly)
        return assembly
    }
    
    static func previewCardViewModel(for card: PreviewCard) -> CardViewModel {
        previewAssembly(for: card).services.cardsRepository.cards[card.card.cardId]!.cardModel!
    }
    
    static var previewAssembly: Assembly {
        .previewAssembly(for: .v4)
    }
    
    var previewCardViewModel: CardViewModel {
        services.cardsRepository.lastScanResult.cardModel!
    }
    
    #if !CLIP
    var previewBlockchain: Blockchain {
        previewCardViewModel.wallets!.first!.blockchain
    }
    #endif
}
