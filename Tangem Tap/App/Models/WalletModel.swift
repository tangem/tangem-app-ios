//
//  WalletModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

class WalletModel: ObservableObject, Identifiable {
    @Published var state: State = .idle
    @Published var balanceViewModel: BalanceViewModel!
    @Published var tokensViewModels: [TokenBalanceViewModel] = []
    @Published var rates: [String: [String: Decimal]] = [:]

    var ratesService: CoinMarketCapService
    var tokensService: TokensService
    var txSender: TransactionSender { walletManager as! TransactionSender }
    var wallet: Wallet { walletManager.wallet }
    
    var addressNames: [String] {
        wallet.addresses.map { $0.localizedName }
    }
    
    var tokens: [Token] { tokensService.cardTokens }
    var canManageTokens: Bool { walletManager.canManageTokens }
    var tokenManager: BlockchainSdk.TokenManager? { walletManager as? BlockchainSdk.TokenManager }
    
    let walletManager: WalletManager
    private var bag = Set<AnyCancellable>()
    private var updateTimer: AnyCancellable? = nil
    
    init(walletManager: WalletManager, ratesService: CoinMarketCapService, tokensService: TokensService) {
        self.walletManager = walletManager
        self.ratesService = ratesService
        self.tokensService = tokensService
        
        updateBalanceViewModel(with: walletManager.wallet, state: .idle)
        self.walletManager.$wallet
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {[unowned self] wallet in
                print("wallet received")
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
        
        self.ratesService
            .$selectedCurrencyCodePublished
            .dropFirst()
            .sink {[unowned self] _ in
                self.loadRates()
            }
            .store(in: &bag)
    }
    
    func update() {
        if case .loading = state {
            return
        }
        
        state = .loading

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
                    self.state = .idle
                    self.loadRates()
                }
            }
        }
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
    
    func addToken(_ token: Token) -> AnyPublisher<Amount, Error>? {
        tokensService.addToken(token)
        return tokenManager?.addToken(token)
            .map { [unowned self] in
                self.updateTokensViewModels()
                self.updateTokensRates([token])
                return $0
            }
            .eraseToAnyPublisher()
    }
    
    func removeToken(_ token: Token) {
        tokensService.removeToken(token)
        tokenManager?.removeToken(token)
        tokensViewModels.removeAll(where: { $0.token == token })
    }
    
    private func updateBalanceViewModel(with wallet: Wallet, state: State) {
        let isLoading = state.error == nil && wallet.amounts.isEmpty

        if !walletManager.canManageTokens, let token = walletManager.cardTokens.first {
            balanceViewModel = BalanceViewModel(isToken: true,
                                                hasTransactionInProgress: wallet.hasPendingTx,
                                                isLoading: isLoading,
                                                loadingError: state.error?.localizedDescription,
                                                name: wallet.amounts[.token(value: token)]?.currencySymbol ?? "",
                                                fiatBalance: getFiatFormatted(for: wallet.amounts[.token(value: token)]) ?? " ",
                                                balance: wallet.amounts[.token(value: token)]?.description ?? "-",
                                                secondaryBalance: wallet.amounts[.coin]?.description ?? "-",
                                                secondaryFiatBalance: getFiatFormatted(for: wallet.amounts[.coin]) ?? "",
                                                secondaryName: wallet.blockchain.displayName )
            tokensViewModels = []
        } else {
            balanceViewModel = BalanceViewModel(isToken: false,
                                                hasTransactionInProgress: wallet.hasPendingTx,
                                                isLoading: isLoading,
                                                loadingError: state.error?.localizedDescription,
                                                name:  wallet.blockchain.displayName,
                                                fiatBalance: getFiatFormatted(for: wallet.amounts[.coin]) ?? " ",
                                                balance: wallet.amounts[.coin]?.description ?? "-",
                                                secondaryBalance: "-",
                                                secondaryFiatBalance: " ",
                                                secondaryName: "-")
            updateTokensViewModels()
        }
    }
    
    private func loadRates() {
        rates = [:]
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
            }) {[unowned self] rates in
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
        tokensViewModels = walletManager.cardTokens.map {
            let amount = wallet.amounts[.token(value: $0)]
            return TokenBalanceViewModel(token: $0, balance: amount?.description ?? "-", fiatBalance: getFiatFormatted(for: amount) ?? " ")
        }
    }
    
    func startUpdatingTimer() {
        updateTimer = Timer.TimerPublisher(interval: 10.0,
                                           tolerance: 0.1,
                                           runLoop: .main,
                                           mode: .common)
            .autoconnect()
            .sink() {[weak self] _ in
                self?.update()
            }
    }
}

extension WalletModel {
    enum State {
        case created
        case idle
        case loading
        case noAccount(message: String)
        case failed(error: Error)
        
        var isLoading: Bool {
            switch self {
            case .loading:
                return true
            default:
                return false
            }
        }
        
        var error: Error? {
            switch self {
            case .failed(let error):
                return error
            default:
                return nil
            }
        }
    }
}
