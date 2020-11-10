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
    
//    var selectedCurrency: String  {
//        get { ratesService.selectedCurrencyCode }
//        set {
//            ratesService.selectedCurrencyCode = newValue
//            loadRates()
//        }
//    }
    
    var txSender: TransactionSender { walletManager as! TransactionSender }
    var wallet: Wallet { walletManager.wallet }
    
    let walletManager: WalletManager
    private var bag = Set<AnyCancellable>()
    private var updateTimer: AnyCancellable? = nil
    
    init(walletManager: WalletManager) {
        self.walletManager = walletManager
        updateBalanceViewModel(with: walletManager.wallet, state: .idle)
        self.walletManager.$wallet
            .combineLatest($state)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {[unowned self] wallet, state in
                print("wallet received")
                self.updateBalanceViewModel(with: wallet, state: state)
                if wallet.hasPendingTx {
                    if self.updateTimer == nil {
                        self.startUpdatingTimer()
                    }
                } else {
                    self.updateTimer = nil
                }
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
        walletManager.update { result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return}
                
                if case let .failure(error) = result {
                    if case let .noAccount(noAccountMessage) = (error as? WalletError) {
                        self.state = .noAccount(message: noAccountMessage)
                    } else {
                        self.state = .failed(error: error.detailedError)
                        Analytics.log(error: error)
                    }
                    
                    self.updateBalanceViewModel(with: self.wallet, state: self.state)
                } else {
                    self.loadRates()
                    self.state = .idle
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
            return (value * rate).rounded(2)
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
    
    private func updateBalanceViewModel(with wallet: Wallet, state: State) {
//        guard loadingError != nil || !wallet.amounts.isEmpty else { //not yet loaded
//            return
//        }
        
        if let token = wallet.token {
            balanceViewModel = BalanceViewModel(isToken: true,
                                                hasTransactionInProgress: wallet.hasPendingTx,
                                                loadingError: state.error?.localizedDescription,
                                                name: token.displayName,
                                                fiatBalance: getFiatFormatted(for: wallet.amounts[.token]) ?? " ",
                                                balance: wallet.amounts[.token]?.description ?? "-",
                                                secondaryBalance: wallet.amounts[.coin]?.description ?? "-",
                                                secondaryFiatBalance: getFiatFormatted(for: wallet.amounts[.coin]) ?? "",
                                                secondaryName: wallet.blockchain.displayName )
        } else {
            balanceViewModel = BalanceViewModel(isToken: false,
                                                hasTransactionInProgress: wallet.hasPendingTx,
                                                loadingError: state.error?.localizedDescription,
                                                name:  wallet.blockchain.displayName,
                                                fiatBalance: getFiatFormatted(for: wallet.amounts[.coin]) ?? " ",
                                                balance: wallet.amounts[.coin]?.description ?? "-",
                                                secondaryBalance: "-",
                                                secondaryFiatBalance: " ",
                                                secondaryName: "-")
        }
    }
    
    private func loadRates() {
        rates = [:]
        let currenciesToExchange = walletManager.wallet.amounts
            .filter({ $0.key != .reserve }).values
            .flatMap({ [$0.currencySymbol: Decimal(1.0)] })
            .reduce(into: [String: Decimal](), { $0[$1.0] = $1.1 })
        
        ratesService?
            .loadRates(for: currenciesToExchange)
            .combineLatest($state)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    Analytics.log(error: error)
                    print(error.localizedDescription)
                case .finished:
                    break
                }
            }) {[unowned self] rates, state in
                self.rates = rates
                self.updateBalanceViewModel(with: self.wallet, state: state)
            }
            .store(in: &bag)
    }
    
    private func startUpdatingTimer() {
        updateTimer = Timer.TimerPublisher(interval: 10.0,
                                           tolerance: 0.1,
                                           runLoop: .main,
                                           mode: .common)
            .autoconnect()
            .sink() {[weak self] _ in
                self?.update(silent: true)
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
