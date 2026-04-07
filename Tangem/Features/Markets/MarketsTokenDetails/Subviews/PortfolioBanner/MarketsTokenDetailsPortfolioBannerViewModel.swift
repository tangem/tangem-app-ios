//
//  MarketsTokenDetailsPortfolioBannerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MarketsTokenDetailsPortfolioBannerViewModel: ObservableObject {
    @Published private(set) var totalFiatBalance: TotalFiatBalanceState = .loading

    private let tokenInfo: MarketsTokenModel
    private let walletDataProvider: MarketsWalletDataProvider

    init(
        tokenInfo: MarketsTokenModel,
        walletDataProvider: MarketsWalletDataProvider
    ) {
        self.tokenInfo = tokenInfo
        self.walletDataProvider = walletDataProvider
        bind()
    }
}

private extension MarketsTokenDetailsPortfolioBannerViewModel {
    func bind() {
        walletDataProvider.userWalletModelsPublisher
            .withWeakCaptureOf(self)
            .flatMap { viewModel, userWalletModels -> AnyPublisher<TotalFiatBalanceState, Never> in
                let publishers = userWalletModels.map { viewModel.tokenBalanceTypesPublisher(for: $0) }

                guard publishers.isNotEmpty else {
                    return Just(.empty).eraseToAnyPublisher()
                }

                return publishers
                    .combineLatest()
                    .map {
                        let tokenBalances = $0.flatMap { $0 }
                        return viewModel.totalFiatBalanceState(from: tokenBalances)
                    }
                    .eraseToAnyPublisher()
            }
            .receiveOnMain()
            .assign(to: &$totalFiatBalance)
    }

    /// Returns a publisher of all `TokenBalanceType` values for matching wallet models in a single user wallet.
    func tokenBalanceTypesPublisher(for userWalletModel: UserWalletModel) -> AnyPublisher<[TokenBalanceType], Never> {
        userWalletModel.accountModelsManager.accountModelsPublisher
            .withWeakCaptureOf(self)
            .flatMap { viewModel, accountModels in
                viewModel.cryptoAccountModels(from: accountModels)
                    .map { viewModel.tokenBalanceTypesPublisher(for: $0) }
                    .combineLatest()
                    .map { $0.flatMap { $0 } }
            }
            .eraseToAnyPublisher()
    }

    /// Returns a publisher of all `TokenBalanceType` values for matching wallet models in a single crypto account.
    func tokenBalanceTypesPublisher(for account: some CryptoAccountModel) -> AnyPublisher<[TokenBalanceType], Never> {
        account.walletModelsManager.walletModelsPublisher
            .flatMap { [tokenInfo] walletModels in
                walletModels.filter { $0.tokenItem.id == tokenInfo.id }
                    .map { $0.fiatTotalTokenBalanceProvider.balanceTypePublisher }
                    .combineLatest()
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Helper Methods

private extension MarketsTokenDetailsPortfolioBannerViewModel {
    func totalFiatBalanceState(from allTypes: [TokenBalanceType]) -> TotalFiatBalanceState {
        // No matching wallet models at all → token not added anywhere
        guard allTypes.isNotEmpty else {
            return .empty
        }

        // Any still loading → whole state is loading
        if allTypes.contains(where: { $0.isLoading }) {
            return .loading
        }

        // All settled — sum up: .empty → 0, .failure → cached ?? 0, .loaded → value
        let total = allTypes.reduce(Decimal(0)) { sum, type_ in
            switch type_ {
            case .empty:
                return sum
            case .loading(let cached), .failure(let cached):
                return sum + (cached?.balance ?? 0)
            case .loaded(let value):
                return sum + value
            }
        }

        return .loaded(total)
    }

    func cryptoAccountModels(from accountModels: [AccountModel]) -> [any CryptoAccountModel] {
        accountModels.cryptoAccounts()
            .reduce(into: []) { result, cryptoAccount in
                switch cryptoAccount {
                case .single(let cryptoAccountModel):
                    result.append(cryptoAccountModel)
                case .multiple(let cryptoAccountModels):
                    result.append(contentsOf: cryptoAccountModels)
                }
            }
    }
}

// MARK: - Types

extension MarketsTokenDetailsPortfolioBannerViewModel {
    enum TotalFiatBalanceState {
        /// At least one balance is still loading
        case loading
        /// Token is not added to any wallet or account
        case empty
        /// All balances resolved
        case loaded(Decimal)
    }
}
