//
//  TangemPaySelectPlanViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPay
import struct TangemUIUtils.AlertBinder

typealias TangemPayProceedToConfirmAction = (
    _ tariffPlan: VisaCustomerInfoResponse.TariffPlan,
    _ transitionType: TangemPayTariffPlanTransition.TransitionType
) -> Void

final class TangemPaySelectPlanViewModel: ObservableObject {
    @Published private(set) var plans: [Plan] = []
    @Published private(set) var isLoading = true
    @Published var selectedPlanID: Plan.ID?
    @Published private(set) var isPlacingOrder = false
    @Published var alert: AlertBinder?

    private let currentTariffPlan: VisaCustomerInfoResponse.TariffPlan?
    private let tariffPlanSelector: any TangemPayTariffPlanSelector
    private let mode: Mode
    private weak var coordinator: TangemPaySelectPlanRoutable?

    private var transitions: TangemPayTariffPlanTransitionsResponse = []

    /// Any non-current plan is selectable; the current plan can't be re-selected.
    var isSelectEnabled: Bool {
        selectedPlan?.isCurrent == false
    }

    var selectedPlan: Plan? {
        plans.first { $0.id == selectedPlanID } ?? plans.first
    }

    var selectedIndex: Int {
        plans.firstIndex { $0.id == selectedPlanID } ?? 0
    }

    init(
        currentTariffPlan: VisaCustomerInfoResponse.TariffPlan? = nil,
        tariffPlanSelector: any TangemPayTariffPlanSelector,
        mode: Mode,
        coordinator: TangemPaySelectPlanRoutable?
    ) {
        self.currentTariffPlan = currentTariffPlan
        self.tariffPlanSelector = tariffPlanSelector
        self.mode = mode
        self.coordinator = coordinator
    }

    func onAppear() {
        if case .onboarding = mode {
            Analytics.log(.visaTiersTierSelectionScreenShowed)
        }
    }

    func onPlanSwiped() {
        Analytics.log(.visaTiersSwiped)
    }

    @MainActor
    func loadTransitions() async {
        isLoading = true
        do {
            let transitions = try await tariffPlanSelector.getTariffPlanTransitions()
            apply(transitions: transitions)
            isLoading = false
        } catch {
            isLoading = false
            alert = makeLoadingFailedAlert()
        }
    }

    func select() {
        guard let plan = selectedPlan, !plan.isCurrent, !isPlacingOrder else {
            return
        }

        Analytics.log(event: .visaTiersPlanSelectedClick, params: [.plan: plan.type])

        switch mode {
        case .planChange(let onProceedToConfirm):
            guard let transition = transitions.first(where: { $0.tariffPlan.id == plan.id }) else {
                return
            }
            onProceedToConfirm(transition.tariffPlan, transition.type)

        case .onboarding:
            guard let transitionType = plan.transitionType else {
                return
            }

            isPlacingOrder = true

            runTask(in: self) { @MainActor viewModel in
                do {
                    try await viewModel.tariffPlanSelector.selectTariffPlan(
                        targetTariffPlanId: plan.id,
                        transitionType: transitionType
                    )
                    viewModel.coordinator?.closeSelectPlanFlow()
                } catch {
                    viewModel.isPlacingOrder = false
                    viewModel.alert = AlertBinder(
                        title: Localization.commonError,
                        message: Localization.commonUnknownError
                    )
                }
            }
        }
    }

    func comparePlans() {
        Analytics.log(.visaTiersComparePlansClicked)

        let tariffPlans = [currentTariffPlan].compactMap { $0 } + transitions.map(\.tariffPlan)
        coordinator?.openComparePlans(tariffPlans: tariffPlans)
    }

    func close() {
        coordinator?.closeSelectPlanFlow()
    }
}

private extension TangemPaySelectPlanViewModel {
    func apply(transitions: TangemPayTariffPlanTransitionsResponse) {
        self.transitions = transitions

        let currentPlan = currentTariffPlan.map { plan in
            Plan(
                id: plan.id,
                type: plan.type,
                name: plan.name,
                imageURL: plan.images.first { $0.type == .main }?.url,
                transitionType: nil,
                isCurrent: true,
                points: Self.makePoints(from: plan.descriptionItems)
            )
        }

        let transitionPlans = transitions.map { transition in
            Plan(
                id: transition.tariffPlan.id,
                type: transition.tariffPlan.type,
                name: transition.tariffPlan.name,
                imageURL: transition.tariffPlan.images.first { $0.type == .main }?.url,
                transitionType: transition.type,
                isCurrent: false,
                points: Self.makePoints(from: transition.tariffPlan.descriptionItems)
            )
        }

        plans = [currentPlan].compactMap { $0 } + transitionPlans
        selectedPlanID = plans.first?.id
    }

    func makeLoadingFailedAlert() -> AlertBinder {
        AlertBinder(
            alert: Alert(
                title: Text(Localization.commonError),
                message: Text(Localization.commonUnknownError),
                primaryButton: .default(Text(Localization.commonRetry)) { [weak self] in
                    guard let self else { return }
                    runTask(in: self) { await $0.loadTransitions() }
                },
                secondaryButton: .cancel(Text(Localization.commonCancel)) { [weak self] in
                    self?.close()
                }
            )
        )
    }
}

private extension TangemPaySelectPlanViewModel {
    static func makePoints(
        from items: [VisaCustomerInfoResponse.TariffPlan.DescriptionItem]
    ) -> [Point] {
        items
            .filter { $0.type == .onboardingRelated }
            .sorted { $0.order < $1.order }
            .map { Point(title: $0.title, subtitle: $0.body) }
    }
}

// MARK: - Types

extension TangemPaySelectPlanViewModel {
    enum Mode {
        case onboarding
        case planChange(onProceedToConfirm: TangemPayProceedToConfirmAction)
    }

    struct Plan: Identifiable {
        let id: String
        let type: String
        let name: String
        let imageURL: String?
        let transitionType: TangemPayTariffPlanTransition.TransitionType?
        let isCurrent: Bool
        let points: [Point]
    }

    struct Point: Identifiable {
        let id = UUID()
        let title: String
        var subtitle: String?
    }
}

// MARK: - Routable

protocol TangemPaySelectPlanRoutable: AnyObject {
    func closeSelectPlanFlow()
    func openComparePlans(tariffPlans: [VisaCustomerInfoResponse.TariffPlan])
}
