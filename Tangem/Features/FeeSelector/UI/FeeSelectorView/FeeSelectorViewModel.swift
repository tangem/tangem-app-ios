//
//  FeeSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

final class FeeSelectorViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Published

    @Published private(set) var viewState: ViewState

    // MARK: - Properties

    private let interactor: any FeeSelectorInteractor

    private let summaryViewModel: FeeSelectorSummaryViewModel
    private let tokensViewModel: FeeSelectorTokensViewModel
    private let feesViewModel: FeeSelectorFeesViewModel

    // MARK: - Dependencies

    private weak var router: FeeSelectorRoutable?

    init(
        interactor: any FeeSelectorInteractor,
        summaryViewModel: FeeSelectorSummaryViewModel,
        tokensViewModel: FeeSelectorTokensViewModel,
        feesViewModel: FeeSelectorFeesViewModel,
        router: FeeSelectorRoutable
    ) {
        self.interactor = interactor
        self.summaryViewModel = summaryViewModel
        self.tokensViewModel = tokensViewModel
        self.feesViewModel = feesViewModel
        self.router = router

        viewState = interactor.selectorFeeTokenItems.hasMultipleFeeItemOptions ? .summary(summaryViewModel) : .fees(feesViewModel)

        summaryViewModel.setup(router: self)
        tokensViewModel.setup(router: self)
        feesViewModel.setup(router: self)
    }

    func userDidTapDismissButton() {
        feesViewModel.userDidRequestRevertCustomFeeValues()
        router?.dismissFeeSelector()
        viewState = interactor.selectorFeeTokenItems.hasMultipleFeeItemOptions ? .summary(summaryViewModel) : .fees(feesViewModel)
    }

    func userDidTapBackButton() {
        feesViewModel.userDidRequestRevertCustomFeeValues()
        viewState = .summary(summaryViewModel)
    }
}

// MARK: - FeeSelectorSummaryRoutable

extension FeeSelectorViewModel: FeeSelectorSummaryRoutable {
    func userDidTapConfirmButton() {
        router?.completeFeeSelection()
    }

    func userDidRequestFeeSelector() {
        viewState = .fees(feesViewModel)
    }

    func userDidRequestTokenSelector() {
        viewState = .tokens(tokensViewModel)
    }
}

// MARK: - FeeSelectorTokensRoutable

extension FeeSelectorViewModel: FeeSelectorTokensRoutable {
    func userDidSelectFeeToken(tokenItem: TokenItem) {
        interactor.userDidSelectTokenItem(tokenItem)
        viewState = .summary(summaryViewModel)
    }
}

// MARK: - FeeSelectorFeesRoutable

extension FeeSelectorViewModel: FeeSelectorFeesRoutable {
    func userDidTapConfirmSelection(selectedFee: TokenFee) {
        interactor.userDidSelectFee(selectedFee)

        if interactor.selectorFeeTokenItems.hasMultipleFeeItemOptions {
            viewState = .summary(summaryViewModel)
        } else {
            router?.completeFeeSelection()
        }
    }
}

extension FeeSelectorViewModel {
    enum ViewState: Equatable {
        case summary(FeeSelectorSummaryViewModel)
        case tokens(FeeSelectorTokensViewModel)
        case fees(FeeSelectorFeesViewModel)

        static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.summary, .summary), (.tokens, .tokens), (.fees, .fees):
                return true
            default:
                return false
            }
        }
    }
}

private extension [TokenItem] {
    var hasMultipleFeeItemOptions: Bool { count > 1 }
}
