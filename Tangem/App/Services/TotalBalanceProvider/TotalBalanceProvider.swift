//
//  TotalBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk

class TotalBalanceProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    private let userWalletModel: UserWalletModel
    private let cardSupportInfo: TotalBalanceCardSupportInfo
    private let totalBalanceSubject = CurrentValueSubject<LoadingValue<TotalBalance>, Never>(.loading)
    private var refreshSubscription: AnyCancellable?
    private let userWalletAmountType: Amount.AmountType?
    private var isFirstLoadForCardInSession: Bool = true
    private let userDefaults = UserDefaults.standard
    
    private var cardBalanceInfoWasSaved: Bool {
        userDefaults.data(forKey: cardSupportInfo.cardNumberHash) != nil
    }

    init(userWalletModel: UserWalletModel, userWalletAmountType: Amount.AmountType?, totalBalanceSupportData: TotalBalanceCardSupportInfo) {
        self.userWalletModel = userWalletModel
        self.cardSupportInfo = totalBalanceSupportData
        self.userWalletAmountType = userWalletAmountType
    }
}

// MARK: - TotalBalanceProviding

extension TotalBalanceProvider: TotalBalanceProviding {
    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalance>, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }

    func updateTotalBalance() {
        totalBalanceSubject.send(.loading)
        loadCurrenciesAndUpdateBalance()
    }
}

private extension TotalBalanceProvider {
    func loadCurrenciesAndUpdateBalance() {
        let tokenItemViewModels = userWalletModel.getWalletModels()
            .flatMap { $0.allTokenItemViewModels() }
            .filter { model in
                guard let amountType = userWalletAmountType else { return true }

                return model.amountType == amountType
            }


        refreshSubscription = tangemApiService.loadCurrencies()
            .tryMap { [unowned self] currencies -> TotalBalance in
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

                self.toppedUpCheck(tokenItemViewModels: tokenItemViewModels, balance: balance)

                if self.isFirstLoadForCardInSession {
                    self.firstLoadBalanceForCard(tokenItemViewModels: tokenItemViewModels, balance: balance)
                    self.isFirstLoadForCardInSession = false
                }

                return TotalBalance(balance: balance, currency: currency, hasError: hasError)
            }
            .receiveValue { [unowned self] balance in
                self.totalBalanceSubject.send(.loaded(balance))
            }
    }

    private func firstLoadBalanceForCard(tokenItemViewModels: [TokenItemViewModel], balance: Decimal) {
        let fullCurrenciesName: String = tokenItemViewModels
            .filter({ $0.fiatValue > 0 })
            .map({ $0.currencySymbol })
            .reduce("") { partialResult, currencySymbol in
                "\(partialResult)\(partialResult.isEmpty ? "" : " / ")\(currencySymbol)"
            }

        var params: [Analytics.ParameterKey: String] = [.state: balance > 0 ? "Full" : "Empty"]
        if !fullCurrenciesName.isEmpty {
            params[.basicCurrency] = fullCurrenciesName
        }
        params[.batchId] = cardSupportInfo.cardBatchId
        Analytics.log(.signedIn, params: params)
    }

    private func toppedUpCheck(tokenItemViewModels: [TokenItemViewModel], balance: Decimal) {
        guard balance > 0 else {
            if !cardBalanceInfoWasSaved {
                let encodedData = try? JSONEncoder().encode(Decimal(0))
                userDefaults.set(encodedData, forKey: cardSupportInfo.cardNumberHash)
            }
            return
        }

        if let data = userDefaults.data(forKey: cardSupportInfo.cardNumberHash),
           let previousBalance = try? JSONDecoder().decode(Decimal.self, from: data)
        {
            if previousBalance == 0 {
                let fullCurrenciesName: String = tokenItemViewModels
                    .filter({ $0.fiatValue > 0 })
                    .map({ $0.currencySymbol })
                    .reduce("") { partialResult, currencySymbol in
                        "\(partialResult)\(partialResult.isEmpty ? "" : " / ")\(currencySymbol)"
                    }
                Analytics.log(.toppedUp, params: [.basicCurrency: fullCurrenciesName])
                let encodeToData = try? JSONEncoder().encode(balance)
                userDefaults.set(encodeToData, forKey: cardSupportInfo.cardNumberHash)
            }
        }
    }
}

extension TotalBalanceProvider {
    struct TotalBalance {
        let balance: Decimal
        let currency: CurrenciesResponse.Currency
        let hasError: Bool
    }
}
