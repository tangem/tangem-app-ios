//
//  ManageTokensItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ManageTokensItemViewModel: Identifiable, ObservableObject {
    // MARK: - Injected Properties

    @Injected(\.tokenQuotesRepository) private var tokenQuotesRepository: TokenQuotesRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Published

    @Published var priceValue: String = ""
    @Published var priceChangeState: TokenPriceChangeView.State = .noData
    @Published var priceHistory: [Double]? = nil
    @Published var action: Action

    // MARK: - Properties

    var id: String { coin.id }
    var imageURL: URL? { TokenIconURLBuilder().iconURL(id: coin.id, size: .large) }
    var name: String { coin.name }
    var symbol: String { coin.symbol }

    let coin: CoinModel
    let didTapAction: (Action, CoinModel) -> Void

    private var bag = Set<AnyCancellable>()

    private var percentFormatter = PercentFormatter()
    private var balanceFormatter = BalanceFormatter()

    // MARK: - Helpers

    var priceHistoryChangeType: ChangeSignType {
        guard
            let priceHistory,
            let firstValue = priceHistory.first,
            let lastValue = priceHistory.last
        else {
            return .positive
        }

        return ChangeSignType(from: Decimal(lastValue - firstValue))
    }

    // MARK: - Init

    init(
        coinModel: CoinModel,
        priceValue: String = "",
        priceChangeState: TokenPriceChangeView.State = .loading,
        priceHistory: [Double]? = nil,
        action: Action,
        didTapAction: @escaping (Action, CoinModel) -> Void
    ) {
        coin = coinModel
        self.priceValue = priceValue
        self.priceChangeState = priceChangeState
        self.priceHistory = nil
        self.action = action
        self.didTapAction = didTapAction

        bind()
    }

    // MARK: - Public Implementation

    func setNeedUpdateAction() {
        action = actionType(for: coin)
    }

    // MARK: - Private Implementation

    private func bind() {
        tokenQuotesRepository.pricesPublisher.sink { [weak self] itemQuote in
            guard let self = self else { return }
            let quote = itemQuote[coin.id]
            update(quote: quote)
        }
        .store(in: &bag)
    }

    private func actionType(for coinModel: CoinModel) -> ManageTokensItemViewModel.Action {
        let userWalletModels = userWalletRepository.models

        let isAlreadyExistToken = userWalletModels.contains(where: { userWalletModel in
            coinModel.items.contains(where: { tokenItem in
                return userWalletModel.userTokensManager.contains(tokenItem, derivationPath: nil)

            })
        })

        return isAlreadyExistToken ? .edit : .add
    }

    private func update(quote: TokenQuote?) {
        if let quote = quote {
            priceChangeState = getPriceChangeState(by: quote)
            priceValue = balanceFormatter.formatFiatBalance(quote.price)
        } else {
            priceChangeState = .noData
            priceValue = ""
        }
    }

    private func getPriceChangeState(by quote: TokenQuote) -> TokenPriceChangeView.State {
        let signType = ChangeSignType(from: quote.change)

        let percent = percentFormatter.percentFormat(value: quote.change)
        return .loaded(signType: signType, text: percent)
    }
}

extension ManageTokensItemViewModel {
    enum Action {
        case add
        case edit
        case info
    }
}
