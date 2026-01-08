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
    var selectedFeeTokenItem: TokenItem? { get }
    var selectedFeeTokenItemPublisher: AnyPublisher<TokenItem?, Never> { get }

    var feeTokenItems: [TokenItem] { get }
    var feeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> { get }
}

protocol FeeSelectorTokensRoutable: AnyObject {
    func userDidSelectFeeToken()
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

    func userDidSelectFeeToken() {
        router?.userDidSelectFeeToken()
    }

    // MARK: - Private Implementation

    private func bind() {
        Publishers.CombineLatest(
            tokensDataProvider.feeTokenItemsPublisher,
            tokensDataProvider.selectedFeeTokenItemPublisher
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .map { viewModel, output in
            let (tokens, selectedToken) = output
            let selectedId = selectedToken?.id
            return tokens.map { token in
                viewModel.mapTokenItemToRowViewModel(token: token, isSelected: selectedId == token.id)
            }
        }
        .assign(to: \.feeCurrencyTokens, on: self, ownership: .weak)
        .store(in: &bag)
    }

    private func mapTokenItemToRowViewModel(token: TokenItem, isSelected: Bool) -> FeeSelectorRowViewModel {
        let subtitleState: LoadableTextView.State = .loading

        return FeeSelectorRowViewModel(
            rowType: .token(tokenIconInfo: TokenIconInfoBuilder().build(from: token, isCustom: false)),
            title: token.name,
            subtitle: subtitleState,
            accessibilityIdentifier: FeeAccessibilityIdentifiers.feeCurrencyOption,
            isSelected: isSelected,
            selectAction: userDidSelectFeeToken
        )
    }
}
