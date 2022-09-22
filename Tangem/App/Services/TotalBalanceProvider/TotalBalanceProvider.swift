//
//  TotalBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import Foundation

class TotalBalanceProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    private let userWalletModel: UserWalletModel
    private let totalBalanceSubject = CurrentValueSubject<LoadingValue<TotalBalance>, Never>(.loading)
    private var refreshSubscription: AnyCancellable?

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
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

extension TotalBalanceProvider {
    struct TotalBalance {
        let balance: Decimal
        let currency: CurrenciesResponse.Currency
        let hasError: Bool
    }
}
