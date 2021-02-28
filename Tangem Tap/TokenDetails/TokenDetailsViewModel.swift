//
//  TokenDetailsViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//
import SwiftUI
import BlockchainSdk
import Combine

class TokenDetailsViewModel: ViewModel {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var topupService: TopupService!
    
    var card: CardViewModel! {
        didSet {
           bind()
        }
    }

    var wallet: Wallet? {
        return walletModel?.wallet
    }
    
    var walletModel: WalletModel? {
        return card.walletModels!.first(where: { $0.wallet.blockchain == blockchain })
    }
    
    var incomingTransactions: [BlockchainSdk.Transaction] {
        wallet?.incomingTransactions ?? []
    }
    
    var outgoingTransactions: [BlockchainSdk.Transaction] {
        wallet?.outgoingTransactions ?? []
    }
    
    var canTopup: Bool {
         card.canTopup
    }
    
    var topupURL: URL? {
        if let wallet = wallet {
            return topupService.getTopupURL(currencySymbol: wallet.blockchain.currencySymbol,
                                     walletAddress: wallet.address)
        }
        return nil
    }
    
    var topupCloseUrl: String {
        topupService.topupCloseUrl.removeLatestSlash()
    }
    
    var canSend: Bool {
        guard card.canSign else {
            return false
        }

        return wallet?.canSend ?? false
    }
    
    var amountToSend: Amount? {
        wallet?.amounts[amountType]
    }
    
    var title: String {
        if let token = amountType.token {
            return token.name
        } else {
            return wallet?.blockchain.displayName ?? ""
        }
    }
    
    @Published var isRefreshing = false
    
    private var bag = Set<AnyCancellable>()
    private let blockchain: Blockchain
    private let amountType: Amount.AmountType
    
    init(blockchain: Blockchain, amountType: Amount.AmountType) {
        self.blockchain = blockchain
        self.amountType = amountType
    }
    
    func onRemove() {
        if let amount = amountToSend, let walletModel = walletModel {
            if amount.type == .coin {
                card.removeBlockchain(walletModel.wallet.blockchain)
            } else if case let .token(token) = amount.type {
                walletModel.removeToken(token)
            }
        }
    }
    
    private func bind() {
        card.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
    }
}
