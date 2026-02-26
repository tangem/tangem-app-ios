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

protocol ExpressApproveFlowRoutable: AnyObject {
    func openFeeTokenSelection()
}

final class ExpressApproveFlowViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - ViewState

    @Published private(set) var state: ViewState

    // MARK: - Dependencies

    private let approveViewModel: ExpressApproveViewModel
    private let feeSelectorViewModel: FeeSelectorTokensViewModel?
    private let feeSelectorInteractor: CommonFeeSelectorInteractor?
    
    // MARK: - Navigation
    
    private weak var feeSelectorOutput: (any FeeSelectorOutput)?
    private weak var coordinatorRouter: ExpressApproveRoutable?

    // MARK: - Init

    init(
        input: ExpressApproveViewModel.Input,
        router: ExpressApproveRoutable,
        feeSelectorViewModel: FeeSelectorTokensViewModel? = nil,
        feeSelectorInteractor: CommonFeeSelectorInteractor? = nil,
        feeSelectorOutput: (any FeeSelectorOutput)? = nil
    ) {
        self.coordinatorRouter = router
        self.feeSelectorViewModel = feeSelectorViewModel
        self.feeSelectorInteractor = feeSelectorInteractor
        self.feeSelectorOutput = feeSelectorOutput

        approveViewModel = ExpressApproveViewModel(
            input: input,
            coordinator: router,
            flowRouter: nil
        )

        state = .approve(approveViewModel)
        setupApproveViewModel()
    }
}

// MARK: - Private

private extension ExpressApproveFlowViewModel {
    func setupApproveViewModel() {
        approveViewModel.setFlowRouter(self)
    }
}

// MARK: - ExpressApproveFlowRoutable

extension ExpressApproveFlowViewModel: ExpressApproveFlowRoutable {
    func openFeeTokenSelection() {
        presentFeeTokenSelection()
    }
}

// MARK: - ExpressApproveRoutable (Proxy to coordinator)

extension ExpressApproveFlowViewModel: ExpressApproveRoutable {
    func didSendApproveTransaction() {
        coordinatorRouter?.didSendApproveTransaction()
    }

    func userDidCancel() {
        coordinatorRouter?.userDidCancel()
    }

    func openLearnMore() {
        coordinatorRouter?.openLearnMore()
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
