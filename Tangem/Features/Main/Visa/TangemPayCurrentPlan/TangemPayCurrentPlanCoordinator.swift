//
//  TangemPayCurrentPlanCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

final class TangemPayCurrentPlanCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var currentPlanViewModel: TangemPayCurrentPlanViewModel?

    // MARK: - Child view models (push navigation)

    @Published var selectPlanViewModel: TangemPaySelectPlanViewModel?

    private var options: Options?
    private var transitions: TangemPayTariffPlanTransitionsResponse = []

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
            customerService: options.customerService,
            coordinator: self
        )
    }
}

// MARK: - Options

extension TangemPayCurrentPlanCoordinator {
    struct Options {
        let customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan
        let customerService: any CustomerInfoManagementService
        let closeFlow: () -> Void
    }
}

// MARK: - TangemPayCurrentPlanRoutable

extension TangemPayCurrentPlanCoordinator: TangemPayCurrentPlanRoutable {
    func openSelectPlan(transitions: TangemPayTariffPlanTransitionsResponse) {
        self.transitions = transitions
        selectPlanViewModel = TangemPaySelectPlanViewModel(transitions: transitions, coordinator: self)
    }
}

// MARK: - TangemPaySelectPlanRoutable

extension TangemPayCurrentPlanCoordinator: TangemPaySelectPlanRoutable {
    func closeSelectPlanFlow() {
        selectPlanViewModel = nil
        options?.closeFlow()
    }

    func openComparePlans() {
        let viewModel = TangemPayComparePlansSheetViewModel(transitions: transitions, coordinator: self)
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - TangemPayComparePlansRoutable

extension TangemPayCurrentPlanCoordinator: TangemPayComparePlansRoutable {
    func closeComparePlans() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
