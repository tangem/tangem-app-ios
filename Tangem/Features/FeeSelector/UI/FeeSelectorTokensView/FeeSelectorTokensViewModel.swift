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

protocol FeeSelectorTokensRoutable: AnyObject {
    func userDidSelectFeeToken()
}

final class FeeSelectorTokensViewModel: ObservableObject {
    // MARK: - Published

    @Published
    private(set) var feeCurrencyTokens = [FeeSelectorRowViewModel]()

    // MARK: - Dependencies

    private let interactor: FeeSelectorInteractor
    private weak var router: FeeSelectorTokensRoutable?

    init(interactor: FeeSelectorInteractor) {
        self.interactor = interactor

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
            interactor.feeTokenItemsPublisher,
            interactor.selectedFeeTokenItemPublisher
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
        .assign(to: &$feeCurrencyTokens)
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
