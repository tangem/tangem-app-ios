//
//  TotalSumBalanceViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

enum ValueState<Value> {
    case loading
    case loaded(_ value: Value)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }

    var value: Value? {
        if case .loaded(let value) = self {
            return value
        }

        return nil
    }
}

extension TotalBalanceManager {
    struct TotalBalance {
        let balance: Decimal
        let currency: CurrenciesResponse.Currency
        let hasError: Bool
    }
}

protocol TotalBalanceManagable {
    func subscribeToTotalBalance() -> AnyPublisher<ValueState<TotalBalanceManager.TotalBalance>, Never>
    func updateTotalBalance()
}

class TotalBalanceManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    private let userWalletModel: UserWalletModel
    private let totalBalanceSubject = CurrentValueSubject<ValueState<TotalBalance>, Never>(.loading)
    private var refreshSubscription: AnyCancellable?

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }
}

extension TotalBalanceManager: TotalBalanceManagable {
    func subscribeToTotalBalance() -> AnyPublisher<ValueState<TotalBalance>, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }

    func updateTotalBalance() {
        totalBalanceSubject.send(.loading)
        loadCurrenciesAndUpdateBalance()
    }
}

private extension TotalBalanceManager {
    func loadCurrenciesAndUpdateBalance() {
        let tokenItemViewModels = userWalletModel.getWalletModels().flatMap { $0.tokenItemViewModels }

        refreshSubscription = tangemApiService.loadCurrencies()
            .tryMap { currencies -> TotalBalance in
                guard let currency = currencies.first(where: { $0.code == AppSettings.shared.selectedCurrencyCode }) else {
                    throw CommonError.noData
                }

                var hasError: Bool = false
                var balance: Decimal = 0.0

                for token in tokenItemViewModels {
                    if token.state.isSuccesfullyLoaded {
                        balance += token.fiatValue
                    }

                    if token.rate.isEmpty || !token.state.isSuccesfullyLoaded {
                        hasError = true
                    }
                }

                return TotalBalance(balance: balance, currency: currency, hasError: hasError)
            }
            .receiveValue { [unowned self] balance in
                self.totalBalanceSubject.send(.loaded(balance))
            }
    }
}

class TotalSumBalanceViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var totalFiatValueString: NSAttributedString = NSAttributedString(string: "")
    @Published var hasError: Bool = false

    /// If we have a note or any single coin wallet that we should show this balance
    @Published var singleWalletBalance: String?

    @Injected(\.rateAppService) private var rateAppService: RateAppService
    private let tapOnCurrencySymbol: () -> ()
    private let isSingleCoinCard: Bool
    private let userWalletModel: UserWalletModel
    private let totalBalanceManager: TotalBalanceManagable

    private var subscribeToSuccessLoadedBag: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(userWalletModel: UserWalletModel,
         totalBalanceManager: TotalBalanceManagable,
         isSingleCoinCard: Bool,
         tapOnCurrencySymbol: @escaping () -> ()
    ) {
        self.userWalletModel = userWalletModel
        self.totalBalanceManager = totalBalanceManager
        self.isSingleCoinCard = isSingleCoinCard
        self.tapOnCurrencySymbol = tapOnCurrencySymbol

        bind()
    }

    func updateBalance() {
        totalBalanceManager.updateTotalBalance()
    }

    func didTapOnCurrencySymbol() {
        tapOnCurrencySymbol()
    }

    func beginUpdates() {
        tapOnCurrencySymbol()
    }

    private func bind() {
        totalBalanceManager.subscribeToTotalBalance()
            .compactMap { $0.value }
            .map { [unowned self] balance in
                addAttributeForBalance(balance.balance, withCurrencyCode: balance.currency.code)
            }
            .weakAssign(to: \.totalFiatValueString, on: self)
            .store(in: &bag)

        totalBalanceManager.subscribeToTotalBalance()
            .compactMap { $0.value?.hasError }
            .removeDuplicates()
            .weakAssign(to: \.hasError, on: self)
            .store(in: &bag)

        totalBalanceManager.subscribeToTotalBalance()
            .map { $0.isLoading }
            .filter { $0 }
            .weakAssignAnimated(to: \.isLoading, on: self)
            .store(in: &bag)

        totalBalanceManager.subscribeToTotalBalance()
            .map { $0.isLoading }
            .filter { !$0 }
            .delay(for: 0.2, scheduler: DispatchQueue.main)
            .weakAssignAnimated(to: \.isLoading, on: self)
            .store(in: &bag)

        userWalletModel.subscribeToWalletModels()
//            .flatMap { walletModels in
//                Publishers
//                    .MergeMany(walletModels.map { $0.$balanceViewModel })
//                    .collect(walletModels.count)
//                    .filter { $0.allConforms { $0?.state.isSuccesfullyLoaded ?? false } }
//                    .map { walletModels.flatMap { $0.balanceViewModel } }
//            }
//            .filter { $0.allConforms { $0?.state.isSuccesfullyLoaded ?? false } }
//            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
//            .removeDuplicates()
            .print("updateBalance")
            .sink { [unowned self] walletModels in
                subscribeToSuccessLoaded(walletModels: walletModels)
//                updateBalance()
            }
            .store(in: &bag)

        guard isSingleCoinCard else { return }

        userWalletModel.subscribeToWalletModels()
            .compactMap { $0.first?.tokenItemViewModels.first?.balance }
            .weakAssign(to: \.singleWalletBalance, on: self)
            .store(in: &bag)
    }

    private func subscribeToSuccessLoaded(walletModels: [WalletModel]) {
        subscribeToSuccessLoadedBag = Publishers
            .MergeMany(walletModels.map { $0.$balanceViewModel })
            .collect(walletModels.count)
            .print("updateBalance")
            .sink { [unowned self] _ in
                updateBalance()
            }
    }

    private func addAttributeForBalance(_ balance: Decimal, withCurrencyCode: String) -> NSAttributedString {
        let formattedTotalFiatValue = balance.currencyFormatted(code: withCurrencyCode)

        let attributedString = NSMutableAttributedString(string: formattedTotalFiatValue)
        let allStringRange = NSRange(location: 0, length: attributedString.length)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 28, weight: .semibold), range: allStringRange)

        let decimalLocation = NSString(string: formattedTotalFiatValue).range(of: balance.decimalSeparator()).location
        if decimalLocation < (formattedTotalFiatValue.count - 1) {
            let locationAfterDecimal = decimalLocation + 1
            let symbolsAfterDecimal = formattedTotalFiatValue.count - locationAfterDecimal
            let rangeAfterDecimal = NSRange(location: locationAfterDecimal, length: symbolsAfterDecimal)

            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 20, weight: .semibold), range: rangeAfterDecimal)
        }

        return attributedString
    }

    private func checkPositiveBalance() {
        guard rateAppService.shouldCheckBalanceForRateApp else { return }

        guard userWalletModel.getWalletModels().contains(where: { !$0.wallet.isEmpty }) else { return }

        rateAppService.registerPositiveBalanceDate()
    }
}
