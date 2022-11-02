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
    private let totalBalanceAnalyticsService: TotalBalanceAnalyticsService?
    private let totalBalanceSubject = CurrentValueSubject<LoadingValue<TotalBalance>, Never>(.loading)
    private var refreshSubscription: AnyCancellable?
    private let userWalletAmountType: Amount.AmountType?
    private var isFirstLoadForCardInSession: Bool = true

    init(userWalletModel: UserWalletModel, userWalletAmountType: Amount.AmountType?, totalBalanceAnalyticsService: TotalBalanceAnalyticsService?) {
        self.userWalletModel = userWalletModel
        self.userWalletAmountType = userWalletAmountType
        self.totalBalanceAnalyticsService = totalBalanceAnalyticsService
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
        refreshSubscription = tangemApiService.loadCurrencies()
            .receive(on: DispatchQueue.global())
            .tryMap { [weak self] currencies -> TotalBalance in
                guard let self = self,
                      let currency = currencies.first(where: { $0.code == AppSettings.shared.selectedCurrencyCode }) else {
                    throw CommonError.noData
                }

                return self.mapToTotalBalance(currency: currency)
            }
            .receive(on: DispatchQueue.main)
            .receiveValue { [weak self] balance in
                self?.totalBalanceSubject.send(.loaded(balance))
            }
    }

    func mapToTotalBalance(currency: CurrenciesResponse.Currency) -> TotalBalance {
        let tokenItemViewModels = getTokenItemViewModels()

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

        totalBalanceAnalyticsService?.sendToppedUpEventIfNeeded(
            tokenItemViewModels: tokenItemViewModels,
            balance: balance
        )

        if isFirstLoadForCardInSession {
            totalBalanceAnalyticsService?.sendFirstLoadBalanceEventForCard(
                tokenItemViewModels: tokenItemViewModels,
                balance: balance
            )
            isFirstLoadForCardInSession = false
        }

        return TotalBalance(balance: balance, currency: currency, hasError: hasError)
    }

    func getTokenItemViewModels() -> [TokenItemViewModel] {
        userWalletModel.getWalletModels()
            .flatMap { $0.allTokenItemViewModels() }
            .filter { model in
                guard let amountType = userWalletAmountType else { return true }

                return model.amountType == amountType
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
