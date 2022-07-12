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
#if !CLIP
    static func previewAssembly(for card: PreviewCard) -> Assembly {
        let assembly = Assembly(isPreview: true)
        let repo = CommonCardsRepository()
        repo.lastScanResult = card.scanResult
        InjectedValues[\.cardsRepository] = repo
        return assembly
    }
    
    static func previewCardViewModel(for card: PreviewCard) -> CardViewModel {
        card.scanResult.cardModel!
    }
    
    static var previewAssembly: Assembly {
        .previewAssembly(for: .cardanoNoteEmptyWallet)
    }
    
    var previewCardViewModel: CardViewModel {
        InjectedValues[\.cardsRepository].lastScanResult.cardModel!
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


enum PreviewCard {
    case withoutWallet, twin, ethereum, stellar, v4, cardanoNote, cardanoNoteEmptyWallet, ethEmptyNote, tangemWalletEmpty
    
    var cardModel: CardViewModel { scanResult.cardModel! }
    
    
    var scanResult: ScanResult {
        let card = Card.card
        let ci = CardInfo(card: card,
                          walletData: walletData,
                          //                              artworkInfo: nil,
                          twinCardInfo: twinInfo,
                          isTangemNote: isNote,
                          isTangemWallet: true)
        let vm = Assembly().makeCardModel(from: ci)
        let scanResult = ScanResult.card(model: vm)
#if !CLIP
        let walletModels: [WalletModel]
        if let blockchain = blockchain {
            let factory = WalletManagerFactory(config: .init(blockchairApiKey: "", blockcypherTokens: [], infuraProjectId: "", tronGridApiKey: ""))
            let walletManager = try! factory.makeWalletManager(cardId: card.cardId, blockchain: blockchain, walletPublicKey: publicKey)
            walletModels = [WalletModel(walletManager: walletManager, derivationStyle: .legacy, defaultToken: nil, defaultBlockchain: nil)]
        } else {
            walletModels = []
        }
        
        walletModels.forEach { $0.initialize() }
        
        vm.state = .loaded(walletModel: walletModels)
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
