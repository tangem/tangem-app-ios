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
    private let totalBalanceSubject = CurrentValueSubject<LoadingValue<TotalBalance>, Never>(.loading)
    private var refreshSubscription: AnyCancellable?
    private let userWalletAmountType: Amount.AmountType?
    private var bag: Set<AnyCancellable> = .init()

    init(userWalletModel: UserWalletModel, userWalletAmountType: Amount.AmountType?) {
        self.userWalletModel = userWalletModel
        self.userWalletAmountType = userWalletAmountType
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

                self?.updateTotalBalance(with: currencyCode, walletModels)
            }
            .store(in: &bag)

        // Subscription to handle balance loading completion
        userWalletModel.subscribeToWalletModels()
            .filter { !$0.isEmpty }
            .receive(on: DispatchQueue.main)
            .flatMap { walletModels -> AnyPublisher<[WalletModel], Never> in
                Publishers.MergeMany(
                    walletModels.map { $0
                        .walletDidChange
                        .filter { !$0.isLoading } // subscribe to all the walletDidChange events
                        // This delay has been added because `walletDidChange` pushed the changes on `willSet`
                        .delay(for: 0.1, scheduler: DispatchQueue.main)
                    })
                    .map { _ in walletModels }
                    .eraseToAnyPublisher()
            }
            .debounce(for: 0.2, scheduler: DispatchQueue.main) // Hide skeleton with delay
            .filter { walletModels in
                // We can still have loading items
                walletModels.allConforms { !$0.state.isLoading }
            }
            .sink { [weak self] walletModels in
                self?.updateTotalBalance(with: AppSettings.shared.selectedCurrencyCode, walletModels)
            }
            .store(in: &bag)
    }

    func updateTotalBalance(with currencyCode: String, _ walletModels: [WalletModel]) {
        let totalBalance = mapToTotalBalance(currencyCode: currencyCode, walletModels)
        totalBalanceSubject.send(.loaded(totalBalance))
    }

    func mapToTotalBalance(currencyCode: String, _ walletModels: [WalletModel]) -> TotalBalance {
        let tokenItemViewModels = getTokenItemViewModels(from: walletModels)

        var hasError = false
        var balance: Decimal = 0.0

        for token in tokenItemViewModels {
            if token.state.isSuccesfullyLoaded {
                balance += token.fiatValue
            }

            if token.rate.isEmpty || !token.state.isSuccesfullyLoaded {
                hasError = true
            }
        }

        // It is also empty when derivation is missing
        if !tokenItemViewModels.isEmpty {
            Analytics.logSignInIfNeeded(balance: balance)
            Analytics.logTopUpIfNeeded(balance: balance)
        }

        return TotalBalance(balance: balance, currencyCode: currencyCode, hasError: hasError)
    }

    func getTokenItemViewModels(from walletModels: [WalletModel]) -> [TokenItemViewModel] {
        walletModels
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
