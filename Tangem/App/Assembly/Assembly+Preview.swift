//
//  Assembly+Preview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

#if !CLIP
import BlockchainSdk
#endif

extension Assembly {
    enum PreviewCard {
        case withoutWallet, twin, ethereum, stellar, v4, cardanoNote, cardanoNoteEmptyWallet, ethEmptyNote, tangemWalletEmpty
        
        static func scanResult(for preview: PreviewCard, assembly: Assembly) -> ScanResult {
            let card = Card.card
            let ci = CardInfo(card: card,
                              walletData: preview.walletData,
//                              artworkInfo: nil,
                              twinCardInfo: preview.twinInfo,
                              isTangemNote: preview.isNote,
                              isTangemWallet: true)
            let vm = assembly.makeCardModel(from: ci)
            let scanResult = ScanResult.card(model: vm)
#if !CLIP
            let walletModels: [WalletModel]
            if let blockchain = preview.blockchain {
                let factory = WalletManagerFactory(config: .init(blockchairApiKey: "", blockcypherTokens: [], infuraProjectId: ""))
                let walletManager = try! factory.makeWalletManager(cardId: card.cardId, blockchain: blockchain, walletPublicKey: preview.publicKey)
                walletModels = [WalletModel(walletManager: walletManager, signer: DummyTransactionSigner(), defaultToken: nil, defaultBlockchain: nil)]
            } else {
                walletModels = []
            }
            
            vm.state = .loaded(walletModel: walletModels)
            assembly.services.cardsRepository.cards[card.cardId] = scanResult
            assembly.services.cardsRepository.lastScanResult = scanResult
#endif
            return scanResult
        }
        
        var walletData: WalletData? {
            switch self {
            case .ethereum:
                return WalletData(blockchain: "ETH", token: nil)
            case .stellar:
                return WalletData(blockchain: "XLM", token: nil)
            case .cardanoNote:
                return WalletData(blockchain: "ADA", token: nil)
            case .ethEmptyNote:
                return WalletData(blockchain: "ETH", token: nil)
            case .cardanoNoteEmptyWallet:
                return WalletData(blockchain: "ADA", token: nil)
            default:
                return nil
            }
        }
 
#if !CLIP
        var blockchain: Blockchain? {
            switch self {
            case .ethereum:
                return .bitcoin(testnet: false)
            case .stellar:
                return .stellar(testnet: false)
            case .cardanoNote:
                return .cardano(shelley: true)
            default:
                return nil
            }
        }
#endif
        
        var publicKey: Data {
            // [REDACTED_TODO_COMMENT]
            switch self {
            default:
                return Data(count: 32)
            }
        }
        
        var isNote: Bool {
            switch self {
            case .cardanoNote, .ethEmptyNote, .cardanoNoteEmptyWallet:
                return true
            default:
                return false
            }
        }
        
        private var twinInfo: TwinCardInfo? {
            switch self {
            case .twin: return TwinCardInfo(cid: "CB64000000006522", series: .cb64, pairPublicKey: nil)
            default: return nil
            }
        }
    }

#if !CLIP
    static func previewAssembly(for card: PreviewCard) -> Assembly {
        let assembly = Assembly(isPreview: true)
        
        let _ = PreviewCard.scanResult(for: card, assembly: assembly)
        assembly.services.cardsRepository.lastScanResult = PreviewCard.scanResult(for: card, assembly: assembly)
        return assembly
    }
    
    static func previewCardViewModel(for card: PreviewCard) -> CardViewModel {
        previewAssembly(for: card).services.cardsRepository.cards[Card.card.cardId]!.cardModel!
    }
    
    static var previewAssembly: Assembly {
        .previewAssembly(for: .cardanoNoteEmptyWallet)
    }
    
    var previewCardViewModel: CardViewModel {
        services.cardsRepository.lastScanResult.cardModel!
    }
#endif
}

#if !CLIP
fileprivate class DummyTransactionSigner: TransactionSigner {
    private let privateKey = Data(repeating: 0, count: 32)
    
    func sign(hashes: [Data], cardId: String, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        Fail(error: WalletError.failedToGetFee).eraseToAnyPublisher()
    }
    
    func sign(hash: Data, cardId: String, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        Fail(error: WalletError.failedToGetFee).eraseToAnyPublisher()
    }
}
#endif
