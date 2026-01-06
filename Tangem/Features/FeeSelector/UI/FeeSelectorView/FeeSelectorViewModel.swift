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
    @Published private(set) var viewState: ViewState

    private let summaryViewModel: FeeSelectorSummaryViewModel
    private let tokensViewModel: FeeSelectorTokensViewModel
    private let feesViewModel: FeeSelectorFeesViewModel

    private weak var output: FeeSelectorOutput?
    private weak var router: FeeSelectorRoutable?

    init(
        summaryViewModel: FeeSelectorSummaryViewModel,
        tokensViewModel: FeeSelectorTokensViewModel,
        feesViewModel: FeeSelectorFeesViewModel,
        output: FeeSelectorOutput,
        router: FeeSelectorRoutable
    ) {
        self.summaryViewModel = summaryViewModel
        self.tokensViewModel = tokensViewModel
        self.feesViewModel = feesViewModel
        self.output = output
        self.router = router

        // [REDACTED_TODO_COMMENT]
        viewState = .fees(feesViewModel)

        summaryViewModel.setup(router: self)
        tokensViewModel.setup(router: self)
        feesViewModel.setup(router: self)
    }

    func userDidTapDismissButton() {
        feesViewModel.userDidRequestRevertCustomFeeValues()
        router?.dismissFeeSelector()
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
    func userDidSelectFeeToken() {
        viewState = .summary(summaryViewModel)
    }
}

// MARK: - FeeSelectorFeesRoutable

extension FeeSelectorViewModel: FeeSelectorFeesRoutable {
    func userDidTapConfirmSelection(selectedFee: FeeSelectorFee) {
        output?.userDidSelect(selectedFee: selectedFee)
        router?.completeFeeSelection()

        // [REDACTED_TODO_COMMENT]
        // viewState = .summary(summaryViewModel)
    }
}

extension FeeSelectorViewModel {
    enum ViewState {
        case summary(FeeSelectorSummaryViewModel)
        case tokens(FeeSelectorTokensViewModel)
        case fees(FeeSelectorFeesViewModel)
    }
}
