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

        switch interactor.state {
        case .single:
            viewState = .fees(feesViewModel, isFeesOnlyMode: true)
        case .multiple:
            viewState = .summary(summaryViewModel)
        }

        summaryViewModel.setup(router: self)
        tokensViewModel.setup(router: self)
        feesViewModel.setup(router: self)
    }

    func userDidTapDismissButton() {
        feesViewModel.userDidRequestRevertCustomFeeValues()
        router?.closeFeeSelector()
    }

    func userDidTapBackButton() {
        assert(interactor.state == .multiple, "Supposed to be called only in .multiple state")

        feesViewModel.userDidRequestRevertCustomFeeValues()
        update(newState: .summary(summaryViewModel))
    }

    /// Delay to avoid broken animations when switching states.
    private func update(newState: ViewState) {
        Task { @MainActor in
            try await Task.sleep(for: .seconds(Constants.stateChangeDelay))
            viewState = newState
        }
    }
}

// MARK: - FeeSelectorSummaryRoutable

extension FeeSelectorViewModel: FeeSelectorSummaryRoutable {
    func userDidTapConfirmButton() {
        interactor.completeSelection()
        router?.closeFeeSelector()
    }

    func userDidRequestFeeSelector() {
        update(newState: .fees(feesViewModel, isFeesOnlyMode: interactor.state == .single))
    }

    func userDidRequestTokenSelector() {
        update(newState: .tokens(tokensViewModel))
    }
}

// MARK: - FeeSelectorTokensRoutable

extension FeeSelectorViewModel: FeeSelectorTokensRoutable {
    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider) {
        interactor.userDidSelect(feeTokenItem: tokenFeeProvider.feeTokenItem)

        update(newState: .summary(summaryViewModel))
    }
}

// MARK: - FeeSelectorFeesRoutable

extension FeeSelectorViewModel: FeeSelectorFeesRoutable {
    func userDidTapConfirmSelection(selectedFee: TokenFee) {
        interactor.userDidSelect(feeOption: selectedFee.option)

        if selectedFee.option == .custom {
            // Don't do any navigation. Waiting `userDidTapManualSaveButton()`
            return
        }

        switch interactor.state {
        case .single:
            interactor.completeSelection()
            router?.closeFeeSelector()

        case .multiple:
            update(newState: .summary(summaryViewModel))
        }
    }

    func userDidTapManualSaveButton() {
        switch interactor.state {
        case .single:
            interactor.completeSelection()
            router?.closeFeeSelector()

        case .multiple:
            update(newState: .summary(summaryViewModel))
        }
    }
}

extension FeeSelectorViewModel {
    enum ViewState: Equatable {
        case summary(FeeSelectorSummaryViewModel)
        case tokens(FeeSelectorTokensViewModel)
        case fees(FeeSelectorFeesViewModel, isFeesOnlyMode: Bool)

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

extension FeeSelectorViewModel {
    enum Constants {
        static let stateChangeDelay: Double = 0.15
    }
}
