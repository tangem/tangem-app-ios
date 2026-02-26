//
//  ExpressApproveFlowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemUI

final class ExpressApproveFlowViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - ViewState

    @Published private(set) var state: ViewState

    // MARK: - Dependencies

    private let approveViewModel: ExpressApproveViewModel
    private let feeSelectorViewModel: FeeSelectorTokensViewModel?
    private let feeSelectorInteractor: CommonFeeSelectorInteractor?
    private weak var feeSelectorOutput: (any FeeSelectorOutput)?

    // MARK: - Init

    init(
        input: ExpressApproveViewModel.Input,
        router: ExpressApproveRoutable,
        feeSelectorViewModel: FeeSelectorTokensViewModel? = nil,
        feeSelectorInteractor: CommonFeeSelectorInteractor? = nil,
        feeSelectorOutput: (any FeeSelectorOutput)? = nil
    ) {
        approveViewModel = ExpressApproveViewModel(input: input, coordinator: router)

        self.feeSelectorViewModel = feeSelectorViewModel
        self.feeSelectorInteractor = feeSelectorInteractor
        self.feeSelectorOutput = feeSelectorOutput

        state = .approve(approveViewModel)
    }
}

// MARK: - FeeSelectorTokensRoutable

extension ExpressApproveFlowViewModel: FeeSelectorTokensRoutable {
    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider) {
        guard let interactor = feeSelectorInteractor else { return }

        interactor.userDidSelect(feeTokenItem: tokenFeeProvider.feeTokenItem)

        feeSelectorOutput?.userDidFinishSelection(
            feeTokenItem: tokenFeeProvider.feeTokenItem,
            feeOption: interactor.selectedTokenFeeOption
        )

        state = .approve(approveViewModel)
    }
}

// MARK: - Public

extension ExpressApproveFlowViewModel {
    func presentFeeTokenSelection() {
        guard let viewModel = feeSelectorViewModel else { return }

        viewModel.setup(router: self)
        state = .feeTokenSelection(viewModel)
    }

    func dismissFeeTokenSelection() {
        state = .approve(approveViewModel)
    }
}

// MARK: - ViewState

extension ExpressApproveFlowViewModel {
    enum ViewState {
        case approve(ExpressApproveViewModel)
        case feeTokenSelection(FeeSelectorTokensViewModel)
    }
}
