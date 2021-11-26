//
//  WalletModel.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class WalletModel: ObservableObject {
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

    let walletManager: WalletManager

    private let selectedCurrencyCode = "USD"

    private var bag: Set<AnyCancellable> = []

    var wallet: Wallet { walletManager.wallet }

    var addressNames: [String] {
        wallet.addresses.map { $0.localizedName }
    }

    init(walletManager: WalletManager) {
        self.walletManager = walletManager

        updateBalanceViewModel(with: walletManager.wallet, state: .idle)
        self.walletManager.$wallet
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {[unowned self] wallet in
//                print("wallet received")
                self.updateBalanceViewModel(with: wallet, state: self.state)
            })
            .store(in: &bag)
    }

    func displayAddress(for index: Int) -> String {
        wallet.addresses[index].value
    }

    func exploreURL(for index: Int) -> URL? {
        wallet.getExploreURL(for: wallet.addresses[index].value)
    }

    func update() -> AnyPublisher<WalletModel, Error>? {
        if case .loading = state {
            return nil
        }

        self.updateBalanceViewModel(with: self.wallet, state: .loading)
        state = .loading
   
        return Future { (promise) in
            self.walletManager.update { result in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    if case let .failure(error) = result {
                        if case let .noAccount(noAccountMessage) = (error as? WalletError) {
                            self.state = .noAccount(message: noAccountMessage)
                        } else {
                            self.state = .failed(error: error)
                            Analytics.log(error: error)
                        }

                        self.updateBalanceViewModel(with: self.wallet, state: self.state)
                        promise(.failure(error))
                    } else {
                        self.state = .idle
                        self.loadRates()
                        promise(.success((self)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getRateFormatted(for amountType: Amount.AmountType) -> String {
        var rateString = ""

        if let amount = wallet.amounts[amountType],
           let quotes = rates[amount.currencySymbol],
           let rate = quotes[selectedCurrencyCode] {
            rateString = rate.currencyFormatted(code: selectedCurrencyCode)
        }

        return rateString
    }

    func getFiatFormatted(for amount: Amount?) -> String? {
        return getFiat(for: amount)?.currencyFormatted(code: selectedCurrencyCode)
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
           let rate = quotes[selectedCurrencyCode] {
            return (value * rate).rounded(scale: 2)
        }
        return nil
    }

    func getCrypto(for value: Decimal, currencySymbol: String) -> Decimal? {
        if let quotes = rates[currencySymbol],
           let rate = quotes[selectedCurrencyCode] {
            return (value / rate).rounded(blockchain: walletManager.wallet.blockchain)
        }
        return nil
    }

    func getBalance(for type: Amount.AmountType) -> String {
        return wallet.amounts[type]?.description ?? ""
    }

    func getFiatBalance(for type: Amount.AmountType) -> String {
        return getFiatFormatted(for: wallet.amounts[type]) ?? ""
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
                                             blockchain: wallet.blockchain)

        let items = tokenViewModels.map {
            TokenItemViewModel(from: balanceViewModel,
                                tokenBalanceViewModel: $0,
                                rate: getRateFormatted(for: .token(value: $0.token)),
                                fiatValue:  getFiat(for: wallet.amounts[.token(value: $0.token)]) ?? 0,
                                blockchain: wallet.blockchain)
        }

        tokenItemViewModels = [blockchainItem] + items
    }

    private func updateBalanceViewModel(with wallet: Wallet, state: State) {
        balanceViewModel = BalanceViewModel(isToken: false,
                                            hasTransactionInProgress: wallet.hasPendingTx, state: state,
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
            }) {[unowned self] rates in
                if !self.rates.isEmpty && rates.isEmpty {
                    return
                }

                if shouldAppendResults {
                    self.rates.merge(rates) { (_, new) in new }
                } else {
                    self.rates = rates
                    self.updateBalanceViewModel(with: self.wallet, state: self.state)
                }

            }
            .store(in: &bag)
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
