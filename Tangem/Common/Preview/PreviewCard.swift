//
//  PreviewCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import BlockchainSdk

enum PreviewCard {
    case withoutWallet
    case twin
    case ethereum
    case stellar
    case v4
    case cardanoNote
    case cardanoNoteEmptyWallet
    case ethEmptyNote
    case tangemWalletEmpty

    var cardModel: CardViewModel {
        let card = Card.card
        let ci = CardInfo(card: card, walletData: walletData)
        let vm = CardViewModel(cardInfo: ci)
        #if !CLIP
        let walletModels: [WalletModel]
        if let blockchain = blockchain {
            let factory = WalletManagerFactory(config: .init(blockchairApiKey: "", blockcypherTokens: [], infuraProjectId: "", tronGridApiKey: ""))
            let walletManager = try! factory.makeWalletManager(blockchain: blockchain, walletPublicKey: publicKey)
            walletModels = [WalletModel(walletManager: walletManager, derivationStyle: .legacy)]
        } else {
            walletModels = []
        }

        walletModels.forEach { $0.initialize() }

        vm.state = .loaded(walletModel: walletModels)
        #endif
        return vm
    }

    var walletData: DefaultWalletData {
        switch self {
        case .ethereum:
            return .v3(WalletData(blockchain: "ETH", token: nil))
        case .stellar:
            return .v3(WalletData(blockchain: "XLM", token: nil))
        case .cardanoNote:
            return .note(WalletData(blockchain: "ADA", token: nil))
        case .ethEmptyNote:
            return .note(WalletData(blockchain: "ETH", token: nil))
        case .cardanoNoteEmptyWallet:
            return .note(WalletData(blockchain: "ADA", token: nil))
        case .twin:
            return .twin(WalletData(blockchain: "BTC", token: nil), TwinCardInfo(cid: "CB64000000006522", series: .cb64, pairPublicKey: nil))
        default:
            return .none
        }
    }

    #if !CLIP
    var blockchain: Blockchain? {
        switch self {
        case .ethereum:
            return .ethereum(testnet: false)
        case .stellar:
            return .stellar(testnet: false)
        case .cardanoNote:
            return .cardano(shelley: true)
        default:
            return nil
        }
    }

    var blockchainNetwork: BlockchainNetwork? {
        blockchain.map { BlockchainNetwork($0) }
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
}
