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
        return card.walletModels?.first(where: { $0.wallet.blockchain == blockchain })
    }
    
    var incomingTransactions: [BlockchainSdk.Transaction] {
        wallet?.incomingTransactions.filter { $0.amount.type == amountType } ?? []
    }
    
    var outgoingTransactions: [BlockchainSdk.Transaction] {
        wallet?.outgoingTransactions.filter { $0.amount.type == amountType } ?? []
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
        
        return wallet?.canSend(amountType: self.amountType) ?? false
    }
    
    var canDelete: Bool {
        if case .noAccount = walletModel?.state {
            return true
        }
        
        guard let amount = amountToSend, let walletModel = self.walletModel else {
            return false
        }
        
        if amount.type == .coin {
            return card.canRemoveBlockchain(walletModel.wallet.blockchain)
        } else {
            return walletModel.canRemove(amountType: amount.type)
        }
    }
    
    var shouldShowTxNote: Bool {
        guard let walletModel = walletModel else { return false }
        
        return walletModel.wallet.hasPendingTx && !walletModel.wallet.hasPendingTx(for: amountType)
    }
    
    var txNoteMessage: String {
        guard let walletModel = walletModel else { return "" }
        
        guard let name = walletModel.wallet.transactions.first?.amount.type.token?.name else { return "" }
        
        return String(format: "token_details_tx_note_message", name)
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
    
    let amountType: Amount.AmountType
    let blockchain: Blockchain
    private var bag = Set<AnyCancellable>()
    
    init(blockchain: Blockchain, amountType: Amount.AmountType) {
        self.blockchain = blockchain
        self.amountType = amountType
    }
    
    func onRemove() {
        if let walletModel = self.walletModel, case .noAccount = walletModel.state {
            card.removeBlockchain(walletModel.wallet.blockchain)
            return
        }

        if let walletModel = self.walletModel {
            if amountType == .coin {
                card.removeBlockchain(walletModel.wallet.blockchain)
            } else if case let .token(token) = amountType {
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
        
        $isRefreshing
            .removeDuplicates()
            .filter { $0 }
            .sink{ [unowned self] _ in
                self.walletModel?.update()
            }
            .store(in: &bag)
        
        walletModel?
            .$state
            .map{ $0.isLoading }
            .filter { !$0 }
            .receive(on: RunLoop.main)
            .sink {[unowned self] _ in
                print("♻️ Wallet model loading state changed")
                withAnimation {
                    self.isRefreshing = false
                }
            }
            .store(in: &bag)
        
        walletModel?.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
    }
}
