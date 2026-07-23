//
//  TangemPayCurrentPlanCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPay

final class TangemPayCurrentPlanCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var currentPlanViewModel: TangemPayCurrentPlanViewModel?

    // MARK: - Child coordinators (push navigation)

    @Published var selectPlanCoordinator: TangemPaySelectPlanCoordinator?

    private var options: Options?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options
        currentPlanViewModel = TangemPayCurrentPlanViewModel(
            customerTariffPlan: options.customerTariffPlan,
            customerTariffPlanPublisher: options.customerTariffPlanPublisher,
            coordinator: self
        )
    }
}

// MARK: - Options

extension TangemPayCurrentPlanCoordinator {
    struct Options {
        let customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan
        let customerTariffPlanPublisher: AnyPublisher<VisaCustomerInfoResponse.CustomerTariffPlan?, Never>
        let tariffPlanSelector: any TangemPayTariffPlanSelector
        let closeFlow: () -> Void
    }
}

// MARK: - TangemPayCurrentPlanRoutable

extension TangemPayCurrentPlanCoordinator: TangemPayCurrentPlanRoutable {
    func openSelectPlan() {
        guard let options else {
            return
        }

        let coordinator = TangemPaySelectPlanCoordinator(
            dismissAction: { [weak self] in
                self?.selectPlanCoordinator = nil
                options.closeFlow()
            },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(
            tariffPlanSelector: options.tariffPlanSelector,
            mode: .planChange(customerTariffPlan: options.customerTariffPlan)
        ))
        selectPlanCoordinator = coordinator
    }

    func openStayOnPlusConfirmation(planName: String, pendingPlanName: String) {
        Task { @MainActor in
            let viewModel = TangemPayStayOnPlusSheetViewModel(
                planName: planName,
                pendingPlanName: pendingPlanName,
                coordinator: self
            )

            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - TangemPayStayOnPlusSheetRoutable

extension TangemPayCurrentPlanCoordinator: TangemPayStayOnPlusSheetRoutable {
    func stayOnCurrentPlan() async throws {
        try await options?.tariffPlanSelector.cancelTariffPlanPendingTransition()
    }

    func closeStayOnPlusSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
