//
//  WalletModel.swift
//  Tangem Tap
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
    @Published var rates: [String: [String: Decimal]] = [:]
    
    weak var ratesService: CoinMarketCapService! {
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
    
    var txSender: TransactionSender { walletManager as! TransactionSender }
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
    
    let walletManager: WalletManager
    private let defaultToken: Token?
    private var bag = Set<AnyCancellable>()
    private var updateTimer: AnyCancellable? = nil
    
    deinit {
        print("🗑 WalletModel deinit")
    }
    
    init(walletManager: WalletManager, defaultToken: Token?) {
        self.defaultToken = defaultToken
        self.walletManager = walletManager
        
        updateBalanceViewModel(with: walletManager.wallet, state: .idle)
        self.walletManager.$wallet
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
        if case .loading = state {
            return
        }
        
        if !silent {
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
                    if !silent {
                        self.state = .idle
                    }
                    self.loadRates()
                }
            }
        }
    }
    
    func getRate(for amountType: Amount.AmountType) -> Decimal {
        if let amount = wallet.amounts[amountType],
           let quotes = rates[amount.currencySymbol],
           let rate = quotes[ratesService.selectedCurrencyCode] {
            return rate
        }
        
        return 0
    }
    
    func getRateFormatted(for amountType: Amount.AmountType) -> String {
        var rateString = ""

        if let amount = wallet.amounts[amountType],
           let quotes = rates[amount.currencySymbol],
           let rate = quotes[ratesService.selectedCurrencyCode] {
            rateString = rate.currencyFormatted(code: ratesService.selectedCurrencyCode)
        }
        
        return rateString
    }
    
    func getFiatFormatted(for amount: Amount?) -> String? {
        return getFiat(for: amount)?.currencyFormatted(code: ratesService.selectedCurrencyCode)
    }
    
    func getFiat(for amount: Amount?) -> Decimal? {
        if let amount = amount {
            return getFiat(for: amount.value, currencySymbol: amount.currencySymbol)
        }
        return nil
    }
    
    func getCrypto(for amount: Amount?) -> Decimal? {
        if let amount = amount {
            return getCrypto(for: amount.value, currencySymbol: amount.currencySymbol)
        }
        return nil
    }
    
    func getFiat(for value: Decimal, currencySymbol: String) -> Decimal? {
        if let quotes = rates[currencySymbol],
           let rate = quotes[ratesService.selectedCurrencyCode] {
            return (value * rate).rounded(scale: 2)
        }
        return nil
    }
    
    func getCrypto(for value: Decimal, currencySymbol: String) -> Decimal? {
        if let quotes = rates[currencySymbol],
           let rate = quotes[ratesService.selectedCurrencyCode] {
            return (value / rate).rounded(blockchain: walletManager.wallet.blockchain)
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
        wallet.getExploreURL(for: wallet.addresses[index].value)
    }
    
    func addToken(_ token: Token, for cardId: String) -> AnyPublisher<Amount, Error>? {
        tokenItemsRepository.append(.token(token), for: cardId)
        return walletManager.addToken(token)
            .map {[weak self] in
                self?.updateTokensViewModels()
                self?.updateTokensRates([token])
                return $0
            }
            .mapError {[weak self] error in
                self?.updateTokensViewModels()
                return error
            }
            .eraseToAnyPublisher()
    }
    
    func canRemove(amountType: Amount.AmountType) -> Bool {
        if let token = amountType.token, token == defaultToken {
            return false
        }
        
        if let amount = wallet.amounts[amountType], !amount.isEmpty {
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
    
    
    func removeToken(_ token: Token, for cardId: String) {
        guard canRemove(amountType: .token(value: token)) else {
            return
        }
        
        tokenItemsRepository.remove(.token(token), for: cardId)
        walletManager.removeToken(token)
        tokenViewModels.removeAll(where: { $0.token == token })
    }
    
    func getBalance(for type: Amount.AmountType) -> String {
        return wallet.amounts[type].map { $0.string(with: 8) } ?? ""
    }
    
    func getFiatBalance(for type: Amount.AmountType) -> String {
        return getFiatFormatted(for: wallet.amounts[type]) ?? ""
    }
    
    func getTokenItem(for type: Amount.AmountType) -> TokenItem {
        if case let .token(token) = type {
            return .token(token)
        }
        
        return .blockchain(wallet.blockchain)
    }
    
    func startUpdatingTimer() {
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
    
    private func updateBalanceViewModel(with wallet: Wallet, state: State) {
        balanceViewModel = BalanceViewModel(isToken: false,
                                            hasTransactionInProgress: wallet.hasPendingTx,
                                            state: self.state,
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
        let currenciesToExchange = walletManager.wallet.amounts
            .filter({ $0.key != .reserve }).values
            .flatMap({ [$0.currencySymbol: Decimal(1.0)] })
            .reduce(into: [String: Decimal](), { $0[$1.0] = $1.1 })
        
        loadRates(for: currenciesToExchange, shouldAppendResults: false)
    }
    
    private func loadRates(for currenciesToExchange: [String: Decimal], shouldAppendResults: Bool) {
        ratesService
            .loadRates(for: currenciesToExchange)
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
                
                if self.rates.count > 0 && rates.count == 0 {
                    return
                }
                
                if shouldAppendResults {
                    self.rates.merge(rates) { (_, new) in new }
                    self.updateTokensViewModels()
                } else {
                    self.rates = rates
                    self.updateBalanceViewModel(with: self.wallet, state: self.state)
                }
                
            }
            .store(in: &bag)
    }
    
    private func updateTokensRates(_ tokens: [Token]) {
        let cardTokens = tokens.map { ($0.symbol, Decimal(1.0)) }
            .reduce(into: [String:Decimal](), { $0[$1.0] = $1.1 })
        
        loadRates(for: cardTokens, shouldAppendResults: true)
    }
    
    private func updateTokensViewModels() {
        tokenViewModels = walletManager.cardTokens.map {
            let type = Amount.AmountType.token(value: $0)
            return TokenBalanceViewModel(token: $0, balance: getBalance(for: type), fiatBalance: getFiatBalance(for: type))
        }
    }
    
    private func updateTokenItemViewModels() {
        let blockchainItem = TokenItemViewModel(from: balanceViewModel,
                                                rate: getRateFormatted(for: .coin),
                                                fiatValue: getFiat(for: wallet.amounts[.coin]) ?? 0,
                                             blockchain: wallet.blockchain,
                                             hasTransactionInProgress: wallet.hasPendingTx(for: .coin))
        
        let items: [TokenItemViewModel] = tokenViewModels.map {
            let amountType = Amount.AmountType.token(value: $0.token)
            return TokenItemViewModel(from: balanceViewModel,
                                tokenBalanceViewModel: $0,
                                rate: getRateFormatted(for: amountType),
                                fiatValue:  getFiat(for: wallet.amounts[amountType]) ?? 0,
                                blockchain: wallet.blockchain,
                                hasTransactionInProgress: wallet.hasPendingTx(for: amountType))
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
