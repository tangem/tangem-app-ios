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

class CardViewModel: Identifiable, ObservableObject {
    let card: Card
    let service = NetworkService()
    var payIDService: PayIDService? = nil
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
    var rates: [String: [String: Decimal]] = [:]
    
    @Published var isWalletLoading: Bool = false
    @Published var loadingError: Error?
    @Published var noAccountMessage: String?
    @Published var isCardSupported: Bool = true
    @Published var payId: PayIdStatus = .notCreated
    @Published var balanceViewModel: BalanceViewModel!
    @Published var wallet: Wallet? = nil
    @Published var image: UIImage? = nil
    @Published var selectedCurrency: String = ""
    @Published var showSendAlert: Bool = false
    
    var walletManager: WalletManager?
    public let verifyCardResponse: VerifyCardResponse?
    
    var canPurgeWallet: Bool  {
        if let status = card.status, status == .empty {
            return false
        }
        
        if (card.settingsMask?.contains(.prohibitPurgeWallet) ?? false) {
            return false
        }
        //[REDACTED_TODO_COMMENT]
        //        if card.cardData?.productMask?.contains(.idCard) ?? true {
        //             return false
        //        }
        //
        //        if card.cardData?.productMask?.contains(.idIssuer) ?? true {
        //             return false
        //        }
        
        if let wallet = self.wallet {
            if !wallet.isEmptyAmount || wallet.hasPendingTx {
                return false
            }
            
            return true
        } else {
            if let loadingError = self.loadingError {
                if case .noAccount(_) = (loadingError as? WalletError) {
                    return true
                } else {
                    return false
                }
            } else {
                return false // [REDACTED_TODO_COMMENT]
            }
        }
    }
    
    private var bag =  Set<AnyCancellable>()
    
    init(card: Card, verifyCardResponse: VerifyCardResponse? = nil) {
        self.card = card
        self.verifyCardResponse = verifyCardResponse
        if let walletManager = WalletManagerFactory().makeWalletManager(from: card) {
            self.walletManager = walletManager
            self.payIDService = PayIDService.make(from: walletManager.wallet.blockchain)
            self.balanceViewModel = self.makeBalanceViewModel(from: walletManager.wallet)
            walletManager.$wallet
                .receive(on: RunLoop.main)
                .sink(receiveValue: {[unowned self] wallet in
                    print("wallet received")
                    self.wallet = wallet
                    self.balanceViewModel = self.makeBalanceViewModel(from: wallet)
                    self.isWalletLoading = false
                })
                .store(in: &bag)
        } else {
            isCardSupported = WalletManagerFactory().isBlockchainSupported(card) 
        }
    }
    
    func loadPayIDInfo () {
        guard let cid = card.cardId, let key = card.cardPublicKey else {
            payId = .notSupported
            return
        }
        
        payIDService?.loadPayId(cid: cid, key: key, completion: { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let payIdString):
                if let payIdString = payIdString {
                    self.payId = .created(payId: payIdString)
                } else {
                    self.payId = .notCreated
                }
            case .failure(let error):
                //[REDACTED_TODO_COMMENT]
                self.payId = .notSupported
            }
        })
    }
    
    func createPayID(_ payIDString: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !payIDString.isEmpty,
            let cid = card.cardId,
            let address = wallet?.address,
            let cardPublicKey = card.cardPublicKey,
            let payIdService = self.payIDService else {
                completion(.failure(PayIdError.unknown))
                return
        }
        
        let fullPayIdString = payIDString + "$payid.tangem.com"
        payIdService.createPayId(cid: cid, key: cardPublicKey, payId: fullPayIdString, address: address) { [weak self] result in
            switch result {
            case .success:
                UIPasteboard.general.string = fullPayIdString
                self?.payId = .created(payId: fullPayIdString)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
    public func update() {
        loadingError = nil
        loadImage()
        if let walletManager = self.walletManager {
            isWalletLoading = true
            loadPayIDInfo()
            walletManager.update { [weak self] result in
                guard let self = self else {return}
                
                DispatchQueue.main.async {
                    if case let .failure(error) = result {
                        self.loadingError = error.detailedError
                        if case let .noAccount(noAccountMessage) = (error as? WalletError) {
                            self.noAccountMessage = noAccountMessage
                        }
                        if let wallet = self.wallet  {
                            self.balanceViewModel = self.makeBalanceViewModel(from: wallet)
                        }
                    } else {
                        self.loadRates()
                    }
                    self.isWalletLoading = false
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isWalletLoading = false
            }
        }
    }
    
    func loadRates() {
        rates = [:]
        if let currenciesToExchange = wallet?.amounts.values
            .flatMap({ [$0.currencySymbol: Decimal(1.0)] })
            .reduce(into: [String: Decimal](), { $0[$1.0] = $1.1 }) {
            ratesService?
                .loadRates(for: currenciesToExchange)
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print(error.localizedDescription)
                    case .finished:
                        break
                    }
                }) {[unowned self] rates in
                    self.rates = rates
                    if let wallet = self.wallet  {
                        self.balanceViewModel = self.makeBalanceViewModel(from: wallet)
                    }
            }
            .store(in: &bag)
            
        }
    }
    
    func loadImage() {
        guard image == nil else {
            return
        }
        
        guard let artworkId = verifyCardResponse?.artworkInfo?.id,
            let cid = card.cardId,
            let cardPublicKey = card.cardPublicKey else {
                self.image = UIImage(named: "card-default")
                return
        }
        
        service.request(TangemEndpoint.artwork(cid: cid, cardPublicKey: cardPublicKey, artworkId: artworkId)) {[weak self] result in
            switch result {
            case .success(let data):
                if let img = UIImage(data: data) {
                    self?.image = img
                }
            case .failure(let error):
                //[REDACTED_TODO_COMMENT]
                break
            }
        }
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
            return value * rate
        }
        return nil
    }
    
    func getCrypto(for value: Decimal, currencySymbol: String) -> Decimal? {
        if let quotes = rates[currencySymbol],
            let rate = quotes[selectedCurrency] {
            return value / rate
        }
        return nil
    }
    
    private func makeBalanceViewModel(from wallet: Wallet) -> BalanceViewModel? {
        if let token = wallet.token {
            return BalanceViewModel(isToken: true,
                                    //dataLoaded: !wallet.amounts.isEmpty,
                                    loadingError: self.loadingError?.localizedDescription,
                                    name: token.displayName,
                                    fiatBalance: getFiatFormatted(for: wallet.amounts[.token]) ?? "-",
                                    balance: wallet.amounts[.token]?.description ?? "-",
                                    secondaryBalance: wallet.amounts[.coin]?.description ?? "-",
                                    secondaryFiatBalance: getFiatFormatted(for: wallet.amounts[.coin]) ?? "-",
                                    secondaryName: wallet.blockchain.displayName )
        } else {
            return BalanceViewModel(isToken: false,
                                    //dataLoaded: !wallet.amounts.isEmpty,
                                    loadingError: self.loadingError?.localizedDescription,
                                    name:  wallet.blockchain.displayName,
                                    fiatBalance: getFiatFormatted(for: wallet.amounts[.coin]) ?? "-",
                                    balance: wallet.amounts[.coin]?.description ?? "-",
                                    secondaryBalance: "-",
                                    secondaryFiatBalance: "-",
                                    secondaryName: "-")
        }
    }
    
    func showSendWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showSendAlert = true
        }
    }
}

enum WalletState {
    case empty
    case initialized
    case loading
    case loaded
    case accountNotCreated(message: String)
    case loadingFailed(message: String)
}

/*class WalletViewModel {
 var balanceViewModel: BalanceViewModel {
 let name = wallet.token != nil ? wallet.token!.displayName :  wallet.blockchain.displayName
 let secondaryName = wallet.token != nil ?  wallet.blockchain.displayName : ""
 
 switch state {
 case .loadingFailed(let message):
 return BalanceViewModel(isToken: wallet.token != nil,
 dataLoaded: false,
 loadingError: message,
 name: name,
 usdBalance: "",
 balance: "-",
 secondaryBalance: "-",
 secondaryName: secondaryName)
 default:
 return BalanceViewModel(isToken: wallet.token != nil,
 dataLoaded: true,
 loadingError: nil,
 name: name,
 usdBalance: "-",
 balance: wallet.amounts[.coin]?.description ?? "-",
 secondaryBalance: "",
 secondaryName: secondaryName)
 
 }
 }
 
 let wallet: Wallet
 
 @Published var state: WalletState = .initialized
 let address: String
 var payId: PayIdStatus
 
 init(wallet: Wallet) {
 self.wallet = wallet
 address = wallet.address
 payId = .notCreated
 //noAccountMessage = "Load 10+ XLM to create account"
 }
 
 
 }*/

struct BalanceViewModel {
    let isToken: Bool
    //let dataLoaded: Bool
    let loadingError: String?
    let name: String
    let fiatBalance: String
    let balance: String
    let secondaryBalance: String
    let secondaryFiatBalance: String
    let secondaryName: String
}
