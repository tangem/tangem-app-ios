//
//  FeeSelectorTokensViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemAccessibilityIdentifiers
import TangemUIUtils

protocol FeeSelectorTokensDataProvider {
    var selectedSelectorTokenFeeProvider: TokenFeeProvider? { get }
    var selectedSelectorTokenFeeProviderPublisher: AnyPublisher<TokenFeeProvider?, Never> { get }

    var selectorTokenFeeProviders: [any TokenFeeProvider] { get }
    var selectorTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> { get }
}

protocol FeeSelectorTokensRoutable: AnyObject {
    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider)
}

final class FeeSelectorTokensViewModel: ObservableObject {
    // MARK: - Published

    @Published
    private(set) var feeCurrencyTokens = [FeeSelectorRowViewModel]()

    // MARK: - Dependencies

    private let tokensDataProvider: FeeSelectorTokensDataProvider
    private weak var router: FeeSelectorTokensRoutable?

    // MARK: - Properties

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(tokensDataProvider: FeeSelectorTokensDataProvider) {
        self.tokensDataProvider = tokensDataProvider

        bind()
    }

    // MARK: - Public Implementation

    func setup(router: FeeSelectorTokensRoutable?) {
        self.router = router
    }

    // MARK: - Private Implementation

    private func bind() {
        Publishers.CombineLatest(
            tokensDataProvider.selectorTokenFeeProvidersPublisher,
            tokensDataProvider.selectedSelectorTokenFeeProviderPublisher
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .map { viewModel, output in
            let (providers, selectedProvider) = output
            let selectedId = selectedProvider?.feeTokenItem
            return providers.map { provider in
                viewModel.mapTokenItemToRowViewModel(tokenFeeProvider: provider, isSelected: selectedId == provider.feeTokenItem)
            }
        }
        .assign(to: \.feeCurrencyTokens, on: self, ownership: .weak)
        .store(in: &bag)
    }

    private func mapTokenItemToRowViewModel(tokenFeeProvider: any TokenFeeProvider, isSelected: Bool) -> FeeSelectorRowViewModel {
        let feeTokenItem = tokenFeeProvider.feeTokenItem
        let subtitleBalanceState = LoadableTokenBalanceViewStateBuilder().build(
            type: tokenFeeProvider.balanceState,
            textBuilder: Localization.commonBalance
        )

        return FeeSelectorRowViewModel(
            rowType: .token(tokenIconInfo: TokenIconInfoBuilder().build(from: feeTokenItem, isCustom: false)),
            title: feeTokenItem.name,
            subtitle: .balance(subtitleBalanceState),
            accessibilityIdentifier: FeeAccessibilityIdentifiers.feeCurrencyOption,
            isSelected: isSelected,
            selectAction: { [weak self] in
                self?.router?.userDidSelectFeeToken(tokenFeeProvider: tokenFeeProvider)
            }
        )
    }
}
