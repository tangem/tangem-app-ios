//
//  TangemPaySelectPlanCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

final class TangemPaySelectPlanCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var selectPlanViewModel: TangemPaySelectPlanViewModel?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let tariffPlanSelector = options.tariffPlanSelector
        selectPlanViewModel = TangemPaySelectPlanViewModel(
            transitionsLoader: { try await tariffPlanSelector.getTariffPlanTransitions() },
            descriptionContext: .onboarding,
            onSelectPlan: { try await tariffPlanSelector.selectTariffPlan(targetTariffPlanId: $0, transitionType: $1) },
            coordinator: self
        )
    }
}

// MARK: - Options

extension TangemPaySelectPlanCoordinator {
    struct Options {
        let tariffPlanSelector: any TangemPayTariffPlanSelector
    }
}

// MARK: - TangemPaySelectPlanRoutable

extension TangemPaySelectPlanCoordinator: TangemPaySelectPlanRoutable {
    func closeSelectPlanFlow() {
        dismiss()
    }

    func openComparePlans(transitions: TangemPayTariffPlanTransitionsResponse) {
        let viewModel = TangemPayComparePlansSheetViewModel(transitions: transitions, coordinator: self)
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - TangemPayComparePlansRoutable

extension TangemPaySelectPlanCoordinator: TangemPayComparePlansRoutable {
    func closeComparePlans() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
