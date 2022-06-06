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
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    
    @Published var alert: AlertBinder? = nil

    var dismissalRequestPublisher: AnyPublisher<Void, Never> {
        dismissalRequestSubject.eraseToAnyPublisher()
    }
    
    var card: CardViewModel! {
        didSet {
            bind()
        }
    }
    
    var wallet: Wallet? {
        return walletModel?.wallet
    }
    
    var walletModel: WalletModel? {
        return card.walletModels?.first(where: { $0.blockchainNetwork == blockchainNetwork })
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
            
            if blockchainNetwork.blockchain.isTestnet {
                return blockchainNetwork.blockchain.testnetFaucetURL
            }
            
            let address = wallet.address
            switch amountType {
            case .coin:
                return exchangeService.getBuyUrl(currencySymbol: blockchainNetwork.blockchain.currencySymbol, amountType: amountType, blockchain: blockchainNetwork.blockchain, walletAddress: address)
            case .token(let token):
                return exchangeService.getBuyUrl(currencySymbol: token.symbol, amountType: amountType, blockchain: blockchainNetwork.blockchain, walletAddress: address)
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
                return exchangeService.getSellUrl(currencySymbol: blockchainNetwork.blockchain.currencySymbol, amountType: amountType, blockchain: blockchainNetwork.blockchain, walletAddress: address)
            case .token(let token):
                return exchangeService.getSellUrl(currencySymbol: token.symbol, amountType: amountType, blockchain: blockchainNetwork.blockchain, walletAddress: address)
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
    
    var sendBlockedReason: String? {
        guard let wallet = walletModel?.wallet,
              let currentAmount = wallet.amounts[amountType], amountType.isToken else { return nil }

        if wallet.hasPendingTx && !wallet.hasPendingTx(for: amountType) { //has pending tx for fee
            return String(format: "token_details_send_blocked_tx_format".localized, wallet.amounts[.coin]?.currencySymbol ?? "")
        }
        
        if !wallet.hasPendingTx && !canSend && !currentAmount.isZero { //no fee
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
        
        return blockchainNetwork.blockchain.tokenDisplayName
    }
    
    @Published var txIndexToPush: Int? = nil
    @Published var unsupportedTokenWarning: String? = nil
    @Published var solanaRentWarning: String? = nil
    @Published var showExplorerURL: URL? = nil
    
    let amountType: Amount.AmountType
    let blockchainNetwork: BlockchainNetwork
    
    var sellCryptoRequest: SellCryptoRequest? = nil
    
    private let dismissalRequestSubject = PassthroughSubject<Void, Never>()
    private var bag = Set<AnyCancellable>()
    private var rentWarningSubscription: AnyCancellable?
    private var refreshCancellable: AnyCancellable? = nil
    private lazy var testnetBuyCrypto: TestnetBuyCryptoService = .init()
    
    init(blockchainNetwork: BlockchainNetwork, amountType: Amount.AmountType) {
        self.blockchainNetwork = blockchainNetwork
        self.amountType = amountType
    }
    
    func updateState() {
        if let cardModel = cardsRepository.lastScanResult.cardModel {
            card = cardModel
        }
    }
    
    func onAppear() {
        updateUnsupportedTokenWarning()
        
        rentWarningSubscription = walletModel?
            .$state
            .filter { !$0.isLoading }
            .receive(on: RunLoop.main)
            .sink {[weak self] _ in
                self?.updateRentWarning()
            }
    }
    
    func onRemove() {
        guard let walletModel = walletModel else {
            assertionFailure("walletModel isn't found")
            return
        }
        
        switch walletModel.removeState(amountType: amountType) {
        case .able:
            deleteToken()
        case .unable:
            showUnableToHideAlert()
        case .ableThroughtAlert:
            showWarningDeleteAlert()
        }
    }
    
    func tradeCryptoAction() {
        navigation.detailsToTradeSheet = true
    }
    
    func buyCryptoAction() {
        if card.cardInfo.card.isDemoCard {
            alert = AlertBuilder.makeDemoAlert()
            return
        }
        
        guard
            card.isTestnet,
            let token = amountType.token,
            case .ethereum(testnet: true) = blockchainNetwork.blockchain
        else {
            if buyCryptoUrl != nil {
                navigation.detailsToBuyCrypto = true
            }
            return
        }
        
        guard let model = walletModel else { return }
        
        testnetBuyCrypto.buyCrypto(.erc20Token(walletManager: model.walletManager, token: token))
    }
    
    func sellCryptoAction() {
        if card.cardInfo.card.isDemoCard {
            alert = AlertBuilder.makeDemoAlert()
            return
        }
        
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
            Analytics.log(event: event, with: [.currencyCode: blockchainNetwork.blockchain.currencySymbol])
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
    
        walletModel?.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
    }
    
    func onRefresh(_ done: @escaping () -> Void) {
        refreshCancellable = walletModel?
            .update()
            .receive(on: RunLoop.main)
            .sink { _ in
                print("♻️ Token wallet model loading state changed")
                done()
            } receiveValue: { _ in 
                
            }
    }
    
    private func updateUnsupportedTokenWarning() {
        let warning: String?
        if let wallet = wallet,
           case .solana = wallet.blockchain,
           !card.cardInfo.card.canSupportSolanaTokens
        {
            warning = "warning_token_send_unsupported_message".localized
        } else {
            warning = nil
        }
        
        self.unsupportedTokenWarning = warning
    }
    
    private func updateRentWarning() {
        guard let rentProvider = walletModel?.walletManager as? RentProvider else {
            return
        }

        rentProvider.rentAmount()
            .zip(rentProvider.minimalBalanceForRentExemption())
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
    
    private func deleteToken() {
        guard let walletModel = walletModel else {
            assertionFailure("WalletModel didn't found")
            return
        }
        
        dismissalRequestSubject.send(())
        
        /// Added the delay to display the deletion in the main screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.card.remove(
                amountType: self.amountType,
                blockchainNetwork: walletModel.blockchainNetwork
            )
        }
    }
    
    private func showUnableToHideAlert() {
        let title = "token_details_unable_hide_alert_title".localized(amountToSend?.currencySymbol ?? "")

        let message = "token_details_unable_hide_alert_message".localized(
            amountToSend?.currencySymbol ?? "",
            walletModel?.blockchainNetwork.blockchain.displayName ?? ""
        )

        alert = warningAlert(title: title, message: message, primaryButton: .default(Text("common_ok")))
    }
    
    private func showWarningDeleteAlert() {
        let title = "token_details_hide_alert_title".localized(amountToSend?.currencySymbol ?? "")
        
        alert = warningAlert(
            title: title,
            message: "token_details_hide_alert_message".localized,
            primaryButton: .destructive(Text("token_details_hide_alert_hide")) { [weak self] in
                self?.deleteToken()
            }
        )
    }

    private func warningAlert(title: String, message: String, primaryButton: Alert.Button) -> AlertBinder {
        let alert = Alert(
            title: Text(title),
            message: Text(message.localized),
            primaryButton: primaryButton,
            secondaryButton: Alert.Button.cancel()
        )
        
        return AlertBinder(alert: alert)
    }
}

extension Int: Identifiable {
    public var id: Int { self }
}
