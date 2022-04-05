//
//  WalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class WalletModel: ObservableObject, Identifiable {
    @Published var state: State = .idle
    @Published var balanceViewModel: BalanceViewModel!
    @Published var tokenItemViewModels: [TokenItemViewModel] = []
    @Published var tokenViewModels: [TokenBalanceViewModel] = []
    @Published var rates: [String: Decimal] = [:]
    
    weak var ratesService: CurrencyRateService! {
        didSet {
            ratesService
                .$selectedCurrencyCodePublished
                .dropFirst()
                .sink {[unowned self] _ in
                    self.loadRates()
                }
                .store(in: &bag)
        }
    }
    weak var tokenItemsRepository: TokenItemsRepository!
    
    var wallet: Wallet { walletManager.wallet }
    
    var addressNames: [String] {
        wallet.addresses.map { $0.localizedName }
    }
    
    var hasBalance: Bool {
        if !state.isSuccesfullyLoaded {
            return false
        }
        
        if wallet.hasPendingTx {
            return true
        }
        
        if !wallet.isEmpty {
            return true
        }
        
        return false
    }
    
    var canCreateOrPurgeWallet: Bool {
        if !wallet.isEmpty || wallet.hasPendingTx {
            return false
        }
        
        return state.canCreateOrPurgeWallet
    }
    
    var fiatValue: Decimal {
        getFiat(for: wallet.amounts[.coin]) ?? 0
    }
    
    var isTestnet: Bool {
        wallet.blockchain.isTestnet
    }
    
    var pendingTransactions: [PendingTransaction] {
        incomingPendingTransactions + outgoingPendingTransactions
    }
    
    var incomingPendingTransactions: [PendingTransaction] {
        wallet.pendingIncomingTransactions.map {
            PendingTransaction(amountType: $0.amount.type,
                               destination: $0.sourceAddress,
                               transferAmount: $0.amount.string(with: 8),
                               canBePushed: false,
                               direction: .incoming)
        }
    }
    
    var outgoingPendingTransactions: [PendingTransaction] {
        //let txPusher = walletManager as? TransactionPusher
        
        return wallet.pendingOutgoingTransactions.map {
            // let isTxStuckByTime = Date().timeIntervalSince($0.date ?? Date()) > Constants.bitcoinTxStuckTimeSec
            
            return PendingTransaction(amountType: $0.amount.type,
                                      destination: $0.destinationAddress,
                                      transferAmount: $0.amount.string(with: 8),
                                      canBePushed: false, // (txPusher?.isPushAvailable(for: $0.hash ?? "") ?? false) && isTxStuckByTime, //[REDACTED_TODO_COMMENT]
                                      direction: .outgoing)
        }
    }
    
    var isEmptyIncludingPendingIncomingTxs: Bool {
        wallet.isEmpty && incomingPendingTransactions.count == 0
    }
    
    var blockchainNetwork: BlockchainNetwork {
        .init(wallet.blockchain, derivationPath: wallet.publicKey.derivationPath)
    }
    
    let walletManager: WalletManager
    let signer: TransactionSigner
    private let defaultToken: Token?
    private let defaultBlockchain: Blockchain?
    private var bag = Set<AnyCancellable>()
    private var updateTimer: AnyCancellable? = nil
    private let demoBalance: Decimal?
    private let cardInfo: CardInfo?
    private var isDemo: Bool { demoBalance != nil }
    private var latestUpdateTime: Date? = nil
    
    deinit {
        print("🗑 WalletModel deinit")
    }
    
    init(walletManager: WalletManager, signer: TransactionSigner, defaultToken: Token?, defaultBlockchain: Blockchain?, demoBalance: Decimal? = nil, cardInfo: CardInfo?) {
        self.defaultToken = defaultToken
        self.defaultBlockchain = defaultBlockchain
        self.walletManager = walletManager
        self.demoBalance = demoBalance
        self.cardInfo = cardInfo
        self.signer = signer
        
        updateBalanceViewModel(with: walletManager.wallet, state: .idle)
        self.walletManager.walletPublisher
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {[unowned self] wallet in
                print("💳 Wallet model received update")
                self.updateBalanceViewModel(with: wallet, state: self.state)
                //                if wallet.hasPendingTx {
                //                    if self.updateTimer == nil {
                //                        self.startUpdatingTimer()
                //                    }
                //                } else {
                //                    self.updateTimer = nil
                //                }
            })
            .store(in: &bag)
    }
    
    func update(silent: Bool = false) {
        if let latestUpdateTime = self.latestUpdateTime,
           latestUpdateTime.distance(to: Date()) <= 10 {
            if !silent {
                self.state = .idle
            }
            return
        }
        
        if case .loading = state {
            return
        }
        
        if !silent {
            updateBalanceViewModel(with: self.wallet, state: .loading)
            state = .loading
        }
        
        print("🔄 Updating wallet model for \(wallet.blockchain)")
        walletManager.update { result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if case let .failure(error) = result {
                    if case let .noAccount(noAccountMessage) = (error as? WalletError) {
                        self.state = .noAccount(message: noAccountMessage)
                    } else {
                        self.state = .failed(error: error.detailedError)
                        Analytics.log(error: error)
                    }
                    self.updateBalanceViewModel(with: self.wallet, state: self.state)
                } else {
                    self.latestUpdateTime = Date()
                    
                    if let demoBalance = self.demoBalance {
                        self.walletManager.wallet.add(coinValue: demoBalance)
                    }
                    
                    if !silent {
                        self.state = .idle
                    }
                    
                    self.loadRates()
                }
            }
        }
    }
    
    func currencyId(for amount: Amount) -> String? {
        switch amount.type {
        case .coin, .reserve:
            return walletManager.wallet.blockchain.id
        case .token(let token):
            return token.id
        }
    }
    
    func getRate(for amountType: Amount.AmountType) -> Decimal {
        if let amount = wallet.amounts[amountType],
           let currencyId = self.currencyId(for: amount),
           let rate = rates[currencyId] {
            return rate
        }
        
        return 0
    }
    
    func getRateFormatted(for amountType: Amount.AmountType) -> String {
        var rateString = ""
        
        if let amount = wallet.amounts[amountType],
           let currencyId = self.currencyId(for: amount),
           let rate = rates[currencyId] {
            rateString = rate.currencyFormatted(code: ratesService.selectedCurrencyCode)
        }
        
        return rateString
    }
    
    
    func getQRReceiveMessage(for amountType: Amount.AmountType? = nil)  -> String {
        let type: Amount.AmountType = amountType ?? wallet.amounts.keys.first(where: { $0.isToken }) ?? .coin
        //todo: handle default token
        let symbol = wallet.amounts[type]?.currencySymbol ?? wallet.blockchain.currencySymbol
        
        if case let .token(token) = amountType {
            return String(format: "address_qr_code_message_token_format".localized,
                          token.name,
                          symbol,
                          wallet.blockchain.displayName)
        } else {
            return String(format: "address_qr_code_message_format".localized,
                          wallet.blockchain.displayName,
                          symbol)
        }
    }
    
    func getFiatFormatted(for amount: Amount?, roundingMode: NSDecimalNumber.RoundingMode = .down) -> String? {
        return getFiat(for: amount, roundingMode: roundingMode)?.currencyFormatted(code: ratesService.selectedCurrencyCode)
    }
    
    func getFiat(for amount: Amount?, roundingMode: NSDecimalNumber.RoundingMode = .down) -> Decimal? {
        if let amount = amount {
            return getFiat(for: amount.value, currencyId: currencyId(for: amount), roundingMode: roundingMode)
        }
        return nil
    }
    
    func getFiat(for value: Decimal, currencyId: String?, roundingMode: NSDecimalNumber.RoundingMode = .down) -> Decimal? {
        if let currencyId = currencyId,
           let rate = rates[currencyId]
        {
            let fiatValue = value * rate
            if fiatValue == 0 {
                return 0
            }
            return max(fiatValue, 0.01).rounded(scale: 2, roundingMode: roundingMode)
        }
        return nil
    }
    
    func getCrypto(for amount: Amount?) -> Decimal? {
        guard
            let amount = amount,
            let currencyId = self.currencyId(for: amount)
        else {
            return nil
        }
        
        if let rate = rates[currencyId] {
            return (amount.value / rate).rounded(scale: amount.decimals)
        }
        return nil
    }
    
    func displayAddress(for index: Int) -> String {
        wallet.addresses[index].value
    }
    
    func shareAddressString(for index: Int) -> String {
        wallet.getShareString(for: wallet.addresses[index].value)
    }
    
    func exploreURL(for index: Int) -> URL? {
        if isDemo {
            return nil
        }
        
        return wallet.getExploreURL(for: wallet.addresses[index].value)
    }
    
    func addTokens(_ tokens: [Token]) {
        latestUpdateTime = nil
        walletManager.addTokens(tokens)
        updateTokensViewModels()
    }
    
    func canRemove(amountType: Amount.AmountType) -> Bool {
        if !state.isSuccesfullyLoaded {
            return false
        }
        
        if let token = amountType.token, token == defaultToken {
            return false
        }
        
        if amountType == .coin, wallet.blockchain == defaultBlockchain {
            return false
        }
        
        if let amount = wallet.amounts[amountType], !amount.isZero {
            return false
        }
        
        if wallet.hasPendingTx(for: amountType) {
            return false
        }
        
        if amountType == .coin && (!wallet.isEmpty || walletManager.cardTokens.count != 0) {
            return false
        }
        
        return true
    }
    
    
    func removeToken(_ token: Token, for cardId: String) -> Bool {
        guard canRemove(amountType: .token(value: token)) else {
            return false
        }
        walletManager.removeToken(token)
        tokenItemsRepository.remove(token, blockchainNetwork: blockchainNetwork, for: cardId)
        updateTokensViewModels()
        return true
    }
    
    func getBalance(for type: Amount.AmountType) -> String {
        return wallet.amounts[type].map { $0.string(with: 8) } ?? ""
    }
    
    func getFiatBalance(for type: Amount.AmountType) -> String {
        return getFiatFormatted(for: wallet.amounts[type]) ?? ""
    }
    
    func startUpdatingTimer() {
        latestUpdateTime = nil
        print("⏰ Starting updating timer for Wallet model")
        updateTimer = Timer.TimerPublisher(interval: 10.0,
                                           tolerance: 0.1,
                                           runLoop: .main,
                                           mode: .common)
        .autoconnect()
        .sink() {[weak self] _ in
            print("⏰ Updating timer alarm ‼️ Wallet model will be updated")
            self?.update()
            self?.updateTimer?.cancel()
        }
    }
    
    func send(_ tx: Transaction) -> AnyPublisher<Void,Error> {
        if isDemo {
            return signer.sign(hash: Data.randomData(count: 32),
                               cardId:wallet.cardId,
                               walletPublicKey: wallet.publicKey)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        }
        
        return walletManager.send(tx, signer: signer)
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: {[weak self] _ in
                self?.startUpdatingTimer()
            })
            .eraseToAnyPublisher()
    }
    
    func isDefaultDerivation(for style: DerivationStyle) -> Bool {
        guard let currentDerivation = self.blockchainNetwork.derivationPath else {
            return true //cards without hd wallets
        }
        
        let defaultDerivation = wallet.blockchain.derivationPath(for: style)
        return defaultDerivation == currentDerivation
    }
    
    private func updateBalanceViewModel(with wallet: Wallet, state: State) {
        balanceViewModel = BalanceViewModel(isToken: false,
                                            hasTransactionInProgress: wallet.hasPendingTx,
                                            state: state,
                                            name:  wallet.blockchain.displayName,
                                            fiatBalance: getFiatBalance(for: .coin),
                                            balance: getBalance(for: .coin),
                                            secondaryBalance: "",
                                            secondaryFiatBalance: "",
                                            secondaryName: "")
        updateTokensViewModels()
        updateTokenItemViewModels()
    }
    
    private func loadRates() {
        let currenciesToExchange = [walletManager.wallet.blockchain.id] + walletManager.cardTokens.compactMap { $0.id }
        
        loadRates(for: Array(currenciesToExchange))
    }
    
    private func loadRates(for currenciesToExchange: [String]) {
        ratesService
            .rates(for: currenciesToExchange)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    Analytics.log(error: error)
                    print(error.localizedDescription)
                case .finished:
                    break
                }
            }) { [weak self] rates in
                guard let self = self else { return }
                
                if !self.rates.isEmpty && rates.count == 0 {
                    return
                }
                
                self.rates = rates
                self.updateBalanceViewModel(with: self.wallet, state: self.state)
                
            }
            .store(in: &bag)
    }
    
    private func updateTokensViewModels() {
        tokenViewModels = walletManager.cardTokens.map {
            let type = Amount.AmountType.token(value: $0)
            return TokenBalanceViewModel(token: $0, balance: getBalance(for: type), fiatBalance: getFiatBalance(for: type))
        }
    }
    
    private func isCustom(_ amountType: Amount.AmountType) -> Bool {
        guard let derivationStyle = cardInfo?.card.derivationStyle else {
            return false
        }
        
        let defaultDerivation = blockchainNetwork.blockchain.derivationPath(for: derivationStyle)
        let derivation = blockchainNetwork.derivationPath ?? defaultDerivation
        
        if derivation != defaultDerivation {
            return true
        }
        
        switch amountType {
        case .coin, .reserve:
            return false
        case .token(let token):
            return token.id == nil
        }
    }
    
    private func updateTokenItemViewModels() {
        let blockchainAmountType = Amount.AmountType.coin
        let blockchainItem = TokenItemViewModel(from: balanceViewModel,
                                                rate: getRateFormatted(for: blockchainAmountType),
                                                fiatValue: getFiat(for: wallet.amounts[blockchainAmountType]) ?? 0,
                                                blockchainNetwork: blockchainNetwork,
                                                hasTransactionInProgress: wallet.hasPendingTx(for: blockchainAmountType),
                                                isCustom: isCustom(blockchainAmountType))
        
        let items: [TokenItemViewModel] = tokenViewModels.map {
            let amountType = Amount.AmountType.token(value: $0.token)
            return TokenItemViewModel(from: balanceViewModel,
                                      tokenBalanceViewModel: $0,
                                      rate: getRateFormatted(for: amountType),
                                      fiatValue:  getFiat(for: wallet.amounts[amountType]) ?? 0,
                                      blockchainNetwork: blockchainNetwork,
                                      hasTransactionInProgress: wallet.hasPendingTx(for: amountType),
                                      isCustom: isCustom(amountType))
        }
        
        tokenItemViewModels = [blockchainItem] + items
    }
}

extension WalletModel {
    enum State: Equatable {
        static func == (lhs: WalletModel.State, rhs: WalletModel.State) -> Bool {
            switch (lhs, rhs) {
            case (.noAccount, noAccount),
                (.created, .created),
                (.idle, .idle),
                (.loading, .loading),
                (.failed, .failed): return true
            default:
                return false
            }
        }
        
        case created
        case idle
        case loading
        case noAccount(message: String)
        case failed(error: Error)
        
        var isLoading: Bool {
            switch self {
            case .loading, .created:
                return true
            default:
                return false
            }
        }
        
        var isSuccesfullyLoaded: Bool {
            switch self {
            case .idle, .noAccount:
                return true
            default:
                return false
            }
        }
        
        var isBlockchainUnreachable: Bool {
            switch self {
            case .failed:
                return true
            default:
                return false
            }
        }
        
        var isNoAccount: Bool {
            switch self {
            case .noAccount:
                return true
            default:
                return false
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .failed(let error):
                return error.localizedDescription
            case .noAccount(let message):
                return message
            default:
                return nil
            }
        }
        
        fileprivate var canCreateOrPurgeWallet: Bool {
            switch self {
            case .failed, .loading, .created:
                return false
            case .noAccount, .idle:
                return true
            }
        }
    }
}
