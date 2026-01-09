//
//  FeeSelectorTokensViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemAccessibilityIdentifiers
import TangemUIUtils

protocol FeeSelectorTokensDataProvider {
    var selectedSelectorFeeTokenItem: TokenItem? { get }
    var selectedSelectorFeeTokenItemPublisher: AnyPublisher<TokenItem?, Never> { get }

    var selectorFeeTokenItems: [TokenItem] { get }
    var selectorFeeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> { get }
}

protocol FeeSelectorTokensRoutable: AnyObject {
    func userDidSelectFeeToken(tokenItem: TokenItem)
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

    func userDidSelectFeeToken(tokenItem: TokenItem) {
        router?.userDidSelectFeeToken(tokenItem: tokenItem)
    }

    // MARK: - Private Implementation

    private func bind() {
        Publishers.CombineLatest(
            tokensDataProvider.selectorFeeTokenItemsPublisher,
            tokensDataProvider.selectedSelectorFeeTokenItemPublisher
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .map { viewModel, output in
            let (tokens, selectedToken) = output
            let selectedId = selectedToken?.id
            return tokens.map { tokenItem in
                viewModel.mapTokenItemToRowViewModel(tokenItem: tokenItem, isSelected: selectedId == tokenItem.id)
            }
        }
        .assign(to: \.feeCurrencyTokens, on: self, ownership: .weak)
        .store(in: &bag)
    }

    private func mapTokenItemToRowViewModel(tokenItem: TokenItem, isSelected: Bool) -> FeeSelectorRowViewModel {
        let subtitleState: LoadableTextView.State = .loading

        return FeeSelectorRowViewModel(
            rowType: .token(tokenIconInfo: TokenIconInfoBuilder().build(from: tokenItem, isCustom: false)),
            title: tokenItem.name,
            subtitle: subtitleState,
            accessibilityIdentifier: FeeAccessibilityIdentifiers.feeCurrencyOption,
            isSelected: isSelected,
            selectAction: { [weak self] in
                self?.userDidSelectFeeToken(tokenItem: tokenItem)
            }
        )
    }
}
