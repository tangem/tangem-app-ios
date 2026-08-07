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
    let dismissAction: Action<DismissReason>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var selectPlanViewModel: TangemPaySelectPlanViewModel?

    // MARK: - Child view models (push navigation)

    @Published var confirmPlanViewModel: TangemPayConfirmPlanViewModel?

    private var options: Options?

    required init(
        dismissAction: @escaping Action<DismissReason>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

        switch options.mode {
        case .onboarding:
            selectPlanViewModel = TangemPaySelectPlanViewModel(
                tariffPlanSelector: options.tariffPlanSelector,
                mode: .onboarding,
                coordinator: self
            )

        case .planChange(let customerTariffPlan):
            selectPlanViewModel = TangemPaySelectPlanViewModel(
                currentTariffPlan: customerTariffPlan.tariffPlan,
                tariffPlanSelector: options.tariffPlanSelector,
                mode: .planChange(
                    onProceedToConfirm: { [weak self] tariffPlan, transitionType in
                        self?.openConfirmPlan(tariffPlan: tariffPlan, transitionType: transitionType)
                    }
                ),
                coordinator: self
            )
        }
    }
}

// MARK: - Options

extension TangemPaySelectPlanCoordinator {
    struct Options {
        let tariffPlanSelector: any TangemPayTariffPlanSelector
        let mode: Mode
    }

    enum Mode {
        case onboarding
        case planChange(customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan)
    }

    enum DismissReason {
        case planUpgraded
        case planDowngraded
        case closed
    }
}

// MARK: - Confirmation

private extension TangemPaySelectPlanCoordinator {
    func openConfirmPlan(
        tariffPlan: VisaCustomerInfoResponse.TariffPlan,
        transitionType: TangemPayTariffPlanTransition.TransitionType
    ) {
        guard let options, case .planChange(let customerTariffPlan) = options.mode else {
            return
        }

        confirmPlanViewModel = TangemPayConfirmPlanViewModel(
            transitionType: transitionType,
            targetPlan: tariffPlan,
            currentPlan: customerTariffPlan.tariffPlan,
            nextBillingAt: customerTariffPlan.nextBillingAt,
            tariffPlanSelector: options.tariffPlanSelector,
            coordinator: self
        )
    }
}

// MARK: - TangemPaySelectPlanRoutable

extension TangemPaySelectPlanCoordinator: TangemPaySelectPlanRoutable {
    func closeSelectPlanFlow() {
        dismiss(with: .closed)
    }

    func planDidActivate() {
        dismiss(with: .planUpgraded)
    }

    func openComparePlans(tariffPlans: [VisaCustomerInfoResponse.TariffPlan]) {
        let viewModel = TangemPayComparePlansSheetViewModel(tariffPlans: tariffPlans, coordinator: self)
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - TangemPayConfirmPlanRoutable

extension TangemPaySelectPlanCoordinator: TangemPayConfirmPlanRoutable {
    func closeConfirmPlan() {
        confirmPlanViewModel = nil
    }

    func confirmPlanDidComplete(transitionType: TangemPayTariffPlanTransition.TransitionType) {
        confirmPlanViewModel = nil

        switch transitionType {
        case .upgrade, .activation:
            dismiss(with: .planUpgraded)
        case .downgrade:
            dismiss(with: .planDowngraded)
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
