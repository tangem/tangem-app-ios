//
//  TokenDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//
import SwiftUI
import BlockchainSdk
import Combine

class TokenDetailsViewModel: ViewModel, ObservableObject {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var exchangeService: ExchangeService!
    
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
    
    var incomingTransactions: [PendingTransaction] {
        walletModel?.incomingPendingTransactions.filter { $0.amountType == amountType } ?? []
    }
    
    var outgoingTransactions: [PendingTransaction] {
        walletModel?.outgoingPendingTransactions.filter { $0.amountType == amountType } ?? []
    }
    
    var canBuyCrypto: Bool {
        card.canExchangeCrypto && buyCryptoUrl != nil
    }
    
    var canSellCrypto: Bool {
        card.canExchangeCrypto && sellCryptoUrl != nil
    }
    
    var buyCryptoUrl: URL? {
        if let wallet = wallet {
            
            if blockchain.isTestnet {
                return URL(string: blockchain.testnetBuyCryptoLink ?? "")
            }
            
            let address = wallet.address
            switch amountType {
            case .coin:
                return exchangeService.getBuyUrl(currencySymbol: blockchain.currencySymbol, blockchain: blockchain, walletAddress: address)
            case .token(let token):
                return exchangeService.getBuyUrl(currencySymbol: token.symbol, blockchain: blockchain, walletAddress: address)
            case .reserve:
                break
            }
        }
        return nil
    }
    
    var buyCryptoCloseUrl: String {
        exchangeService.successCloseUrl.removeLatestSlash()
    }
    
    var sellCryptoRequestUrl: String {
        exchangeService.sellRequestUrl.removeLatestSlash()
    }
    
    var sellCryptoUrl: URL? {
        if let wallet = wallet {
            
            let address = wallet.address
            switch amountType {
            case .coin:
                return exchangeService.getSellUrl(currencySymbol: blockchain.currencySymbol, blockchain: blockchain, walletAddress: address)
            case .token(let token):
                return exchangeService.getSellUrl(currencySymbol: token.symbol, blockchain: blockchain, walletAddress: address)
            case .reserve:
                break
            }
        }
        
        return nil
    }
    
    var canSend: Bool {
        guard card.canSign else {
            return false
        }
        
        return wallet?.canSend(amountType: self.amountType) ?? false
    }
    
    var canDelete: Bool {
        return card.canRemove(amountType: amountType, blockchain: blockchain)
//        let canRemoveAmountType = walletModel.canRemove(amountType: amountType)
//        if case .noAccount = walletModel.state, canRemoveAmountType {
//            return true
//        }
//
//        if amountType == .coin {
//            return card.canRemoveBlockchain(walletModel.wallet.blockchain)
//        } else {
//            return canRemoveAmountType
//        }
    }
    
    var sendBlockedReason: String? {
        guard let wallet = walletModel?.wallet,
              let currentAmount = wallet.amounts[amountType], amountType.isToken else { return nil }

        if wallet.hasPendingTx && !wallet.hasPendingTx(for: amountType) { //has pending tx for fee
            return String(format: "token_details_send_blocked_tx_format".localized, wallet.amounts[.coin]?.currencySymbol ?? "")
        }
        
        if !wallet.hasPendingTx && !canSend && !currentAmount.isEmpty { //no fee
            return String(format: "token_details_send_blocked_fee_format".localized, wallet.blockchain.displayName, wallet.blockchain.displayName)
        }
        
        return nil
    }
    
    var amountToSend: Amount? {
        wallet?.amounts[amountType]
    }
    
    var transactionToPush: BlockchainSdk.Transaction? {
        guard let index = txIndexToPush else { return nil }
        
        return wallet?.pendingOutgoingTransactions[index]
    }
    
    var title: String {
        if let token = amountType.token {
            return token.name
        } else {
            return wallet?.blockchain.displayName ?? ""
        }
    }
    
    var tokenSubtitle: String? {
        if amountType.token == nil {
            return nil
        }
        
        return blockchain.tokenDisplayName
    }
    
    @Published var isRefreshing = false
    @Published var txIndexToPush: Int? = nil
    @Published var solanaRentWarning: String? = nil
    @Published var showExplorerURL: URL? = nil
    
    let amountType: Amount.AmountType
    let blockchain: Blockchain
    
    var sellCryptoRequest: SellCryptoRequest? = nil
    
    private var bag = Set<AnyCancellable>()
    
    init(blockchain: Blockchain, amountType: Amount.AmountType) {
        self.blockchain = blockchain
        self.amountType = amountType
    }
    
    func onRemove() {
        card.remove(amountType: amountType, blockchain: blockchain)
    }
    
    func buyCryptoAction() {
        guard
            card.isTestnet,
            let token = amountType.token,
            case .ethereum(testnet: true) = token.blockchain
        else {
            if buyCryptoUrl != nil {
                navigation.detailsToBuyCrypto = true
            }
            return
        }
        
        guard let model = walletModel else { return }
        
        TestnetBuyCryptoService.buyCrypto(.erc20Token(walletManager: model.walletManager, token: token))
    }
    
    func sellCryptoAction() {
        navigation.detailsToSellCrypto = true
    }
    
    func pushOutgoingTx(at index: Int) {
        resetViewModel(of: PushTxViewModel.self)
        txIndexToPush = index
    }
    
    func processSellCryptoRequest(_ request: String) {
        guard let request = exchangeService.extractSellCryptoRequest(from: request) else {
            return
        }
        
        resetViewModel(of: SendViewModel.self)
        sellCryptoRequest = request
        navigation.detailsToSend = true
    }
    
    func sendButtonAction() {
        resetViewModel(of: SendViewModel.self)
        sellCryptoRequest = nil
        navigation.detailsToSend = true
    }
    
    func sendAnalyticsEvent(_ event: Analytics.Event) {
        switch event {
        case .userBoughtCrypto:
            Analytics.log(event: event, with: [.currencyCode: blockchain.currencySymbol])
        default:
            break
        }
    }
    
    private func resetViewModel<T>(of typeToReset: T) {
        assembly.reset(key: String(describing: type(of: typeToReset)))
    }
    
    private func bind() {
        print("🔗 Token Details view model updates binding")
        card.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
        
        $isRefreshing
            .removeDuplicates()
            .filter { $0 }
            .delay(for: 1, scheduler: DispatchQueue.main)
            .sink{ [weak self] _ in
                self?.walletModel?.update()
            }
            .store(in: &bag)
        
        walletModel?
            .$state
            .removeDuplicates()
//            .print("🐼 TokenDetailsViewModel: Wallet model state")
            .map{ $0.isLoading }
            .filter { !$0 }
            .delay(for: 1, scheduler: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .sink {[weak self] _ in
                print("♻️ Token wallet model loading state changed")
                withAnimation {
                    self?.isRefreshing = false
                }
            }
            .store(in: &bag)
        
        walletModel?.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
        
        if let rentProvider = walletModel?.walletManager as? RentProvider {
            Publishers.Zip(rentProvider.rentAmount(), rentProvider.minimalBalanceForRentExemption())
                .receive(on: RunLoop.main)
                .sink { _ in

                } receiveValue: { [weak self] (rentAmount, minimalBalanceForRentExemption) in
                    guard
                        let self = self,
                        let amount = self.walletModel?.wallet.amounts[.coin],
                        amount < minimalBalanceForRentExemption
                    else {
                        self?.solanaRentWarning = nil
                        return
                    }
                    self.solanaRentWarning = String(format: "solana_rent_warning".localized, rentAmount.description, minimalBalanceForRentExemption.description)
                }
                .store(in: &bag)
        }
    }
}

extension Int: Identifiable {
    public var id: Int { self }
}
