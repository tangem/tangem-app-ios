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
    private var bag: Set<AnyCancellable> = .init()

    init(userWalletModel: UserWalletModel, userWalletAmountType: Amount.AmountType?, totalBalanceAnalyticsService: TotalBalanceAnalyticsService?) {
        self.userWalletModel = userWalletModel
        self.userWalletAmountType = userWalletAmountType
        self.totalBalanceAnalyticsService = totalBalanceAnalyticsService
        bind()
    }
}

// MARK: - TotalBalanceProviding

extension TotalBalanceProvider: TotalBalanceProviding {
    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalance>, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}

private extension TotalBalanceProvider {
    func bind() {
        // Subscription to handle token changes
        userWalletModel.subscribeToWalletModels()
            .combineLatest(AppSettings.shared.$selectedCurrencyCode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] walletModels, currencyCode in
                let hasLoading = !walletModels.filter { $0.state.isLoading }.isEmpty

                // We should wait for balance loading to complete
                if hasLoading {
                    self?.totalBalanceSubject.send(.loading)
                    return
                }

                self?.tryUpdateTotalBalance(with: currencyCode)
            }
            .store(in: &bag)

        // Subscription to handle balance loading completion
        userWalletModel.subscribeToWalletModels()
            .filter { !$0.isEmpty }
            .receive(on: DispatchQueue.main)
            .flatMap { walletModels -> AnyPublisher<Void, Never> in
                Publishers.MergeMany(
                    walletModels.map { $0
                        .walletDidChange
                        .filter { !$0.isLoading } // subscribe to all the walletDidChange events
                        // This delay has been added because `walletDidChange` pushed the changes on `willSet`
                        .delay(for: 0.1, scheduler: DispatchQueue.main)
                    })
                    .mapVoid()
                    .eraseToAnyPublisher()
            }
            .debounce(for: 0.2, scheduler: DispatchQueue.main) // Hide skeleton with delay
            .sink { [weak self] walletModels in
                self?.tryUpdateTotalBalance(with: AppSettings.shared.selectedCurrencyCode)
            }
            .store(in: &bag)
    }

    func tryUpdateTotalBalance(with currencyCode: String) {
        let tokenItemViewModels = getTokenItemViewModels()
        guard tokenItemViewModels.allConforms({ !$0.state.isLoading }) else {
            // We still have loading items
            return
        }

        let totalBalance = mapToTotalBalance(currencyCode: currencyCode, tokenItemViewModels: tokenItemViewModels)
        totalBalanceSubject.send(.loaded(totalBalance))
    }

    func mapToTotalBalance(currencyCode: String, tokenItemViewModels: [TokenItemViewModel]) -> TotalBalance {
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

        return TotalBalance(balance: balance, currencyCode: currencyCode, hasError: hasError)
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
        let currencyCode: String
        let hasError: Bool
    }
}
