//
//  CardViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import Combine
import Alamofire
import  SwiftUI


class CardViewModel: Identifiable, ObservableObject {
    @Published var cardInfo: CardInfo
    var workaroundsService: WorkaroundsService!
    var payIDService: PayIDService? = nil
    
    let walletManager: WalletManager
    
    var ratesService: CoinMarketCapService! {
        didSet {
            selectedCurrency = ratesService.selectedCurrencyCode
            $selectedCurrency
                .dropFirst()
                .sink(receiveValue: { [unowned self] value in
                    self.ratesService.selectedCurrencyCode = value
                    self.loadRates()
                })
                .store(in: &bag)
        }
    }
    
    @Published var rates: [String: [String: Decimal]] = [:]
    @Published var state: State = .idle
    @Published var payId: PayIdStatus = .notSupported
    @Published var balanceViewModel: BalanceViewModel!
    @Published var selectedCurrency: String = ""
    @Published private(set) var currentSecOption: SecurityManagementOption = .longTap
    
    public var canSign: Bool {
        let isPin2Default = cardInfo.card.isPin2Default ?? true
        let hasSmartSecurityDelay = cardInfo.card.settingsMask?.contains(.smartSecurityDelay) ?? false
        let canSkipSD = hasSmartSecurityDelay && !isPin2Default
        
        if let fw = cardInfo.card.firmwareVersionValue, fw < 2.28 {
            if let securityDelay = cardInfo.card.pauseBeforePin2, securityDelay > 1500 && !canSkipSD {
                return false
            }
        }
        
        return true
    }
    
    public var canPurgeWallet: Bool {
        if let status = cardInfo.card.status, status == .empty {
            return false
        }
        
        if cardInfo.card.settingsMask?.contains(.prohibitPurgeWallet) ?? false {
            return false
        }
        
        if case .noAccount = state  {
            return true
        }
        
        if case .failed = state  {
            return false
        }
        
        if !walletManager.wallet.isEmptyAmount || walletManager.wallet.hasPendingTx {
            return false
        }
        
        return true
    }
    
    var canManageSecurity: Bool {
        cardInfo.card.isPin1Default != nil &&
            cardInfo.card.isPin2Default != nil
    }
    
    public var canTopup: Bool { workaroundsService.isTopupSupported(for: cardInfo.card) }
    private var bag =  Set<AnyCancellable>()
    private var updateTimer: AnyCancellable? = nil
    
    init(cardInfo: CardInfo, walletManager: WalletManager) {
        self.cardInfo = cardInfo
        self.walletManager = walletManager
        updateCurrentSecOption()
        self.walletManager.$wallet
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {[unowned self] wallet in
                print("wallet received")
                self.balanceViewModel = self.makeBalanceViewModel(from: wallet)
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
    
    func updateCurrentSecOption() {
        if !(cardInfo.card.isPin1Default ?? true) {
            self.currentSecOption = .accessCode
        } else if !(cardInfo.card.isPin2Default ?? true) {
            self.currentSecOption = .passCode
        }
        else {
            self.currentSecOption = .longTap
        }
    }
    
    func loadPayIDInfo () {
        payIDService?
            .loadPayIDInfo(for: cardInfo.card)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        Analytics.log(error: error)
                        print(error.localizedDescription)
                    case .finished:
                        break
                    }}){ [unowned self] status in
                self.payId = status
            }
            .store(in: &bag)
    }

    func createPayID(_ payIDString: String, completion: @escaping (Result<Void, Error>) -> Void) { //todo: move to payidservice
        guard !payIDString.isEmpty,
            let cid = cardInfo.card.cardId,
            let cardPublicKey = cardInfo.card.cardPublicKey,
            let payIdService = self.payIDService else {
                completion(.failure(PayIdError.unknown))
                return
        }

        let fullPayIdString = payIDString + "$payid.tangem.com"
        payIdService.createPayId(cid: cid, key: cardPublicKey,
                                 payId: fullPayIdString,
                                 address: walletManager.wallet.address) { [weak self] result in
            switch result {
            case .success:
                UIPasteboard.general.string = fullPayIdString
                self?.payId = .created(payId: fullPayIdString)
                completion(.success(()))
            case .failure(let error):
                Analytics.log(error: error)
                completion(.failure(error))
            }
        }

    }
    
    
    public func update(silent: Bool = false) {
        if case .loading = state {
            return
        }
        
        if !silent {
            state = .loading
        }
        
        loadPayIDInfo()
        walletManager.update { [weak self] result in
            guard let self = self else {return}
            
            DispatchQueue.main.async {
                if case let .failure(error) = result {
                    self.state = .failed(error: error.detailedError)
                    if case let .noAccount(noAccountMessage) = (error as? WalletError) {
                        self.state = .noAccount(message: noAccountMessage)
                    } else {
                        Analytics.log(error: error)
                    }
                    
                    self.balanceViewModel = self.makeBalanceViewModel(from: self.walletManager.wallet)
                    
                } else {
                    self.loadRates()
                }
                
                self.state = .idle
            }
        }
    }
    
    func loadRates() {
        rates = [:]
        let currenciesToExchange = walletManager.wallet.amounts
            .filter({ $0.key != .reserve }).values
            .flatMap({ [$0.currencySymbol: Decimal(1.0)] })
            .reduce(into: [String: Decimal](), { $0[$1.0] = $1.1 })
        
        ratesService?
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
                self.rates = rates
                self.balanceViewModel = self.makeBalanceViewModel(from: walletManager.wallet)
            }
            .store(in: &bag)
    }
    
   
    func getFiatFormatted(for amount: Amount?) -> String? {
        return getFiat(for: amount)?.currencyFormatted(code: selectedCurrency)
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
            let rate = quotes[selectedCurrency] {
            return (value * rate).rounded(2)
        }
        return nil
    }
    
    func getCrypto(for value: Decimal, currencySymbol: String) -> Decimal? {
        if let quotes = rates[currencySymbol],
            let rate = quotes[selectedCurrency] {
            return (value / rate).rounded(blockchain: walletManager.wallet.blockchain)
        }
        return nil
    }
    
    private func makeBalanceViewModel(from wallet: Wallet) -> BalanceViewModel? {
        var loadingError: Error?
        if case let .failed(error) = state {
            loadingError = error
        }
        
        guard loadingError != nil || !wallet.amounts.isEmpty else { //not yet loaded
            return self.balanceViewModel
        }

        if let token = wallet.token {
            return BalanceViewModel(isToken: true,
                                    hasTransactionInProgress: wallet.hasPendingTx,
                                    loadingError: loadingError?.localizedDescription,
                                    name: token.displayName,
                                    fiatBalance: getFiatFormatted(for: wallet.amounts[.token]) ?? " ",
                                    balance: wallet.amounts[.token]?.description ?? "-",
                                    secondaryBalance: wallet.amounts[.coin]?.description ?? "-",
                                    secondaryFiatBalance: getFiatFormatted(for: wallet.amounts[.coin]) ?? "",
                                    secondaryName: wallet.blockchain.displayName )
        } else {
            return BalanceViewModel(isToken: false,
                                    hasTransactionInProgress: wallet.hasPendingTx,
                                    loadingError: loadingError?.localizedDescription,
                                    name:  wallet.blockchain.displayName,
                                    fiatBalance: getFiatFormatted(for: wallet.amounts[.coin]) ?? " ",
                                    balance: wallet.amounts[.coin]?.description ?? "-",
                                    secondaryBalance: "-",
                                    secondaryFiatBalance: " ",
                                    secondaryName: "-")
        }
    }
    
    private func startUpdatingTimer() {
        updateTimer = Timer.TimerPublisher(interval: 10.0,
                                           tolerance: 0.1,
                                           runLoop: .main,
                                           mode: .common)
            .autoconnect()
            .sink() {[weak self] _ in
                self?.cardViewModel.update(silent: true)
        }
    }
}

extension CardViewModel {
    enum State {
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
    }
}


struct BalanceViewModel {
    let isToken: Bool
    let hasTransactionInProgress: Bool
    let loadingError: String?
    let name: String
    let fiatBalance: String
    let balance: String
    let secondaryBalance: String
    let secondaryFiatBalance: String
    let secondaryName: String
}
