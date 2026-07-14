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

typealias TangemPaySelectPlanAction = (
    _ targetTariffPlanId: String,
    _ transitionType: TangemPayTariffPlanTransition.TransitionType
) async throws -> Void

final class TangemPaySelectPlanViewModel: ObservableObject {
    let navigationTitle = Localization.tangempaySelectPlanTitle
    let comparePlansButtonTitle = Localization.tangempaySelectPlanCompare

    @Published private(set) var plans: [Plan] = []
    @Published private(set) var isLoading = true
    @Published var selectedPlanID: Plan.ID?
    @Published private(set) var isPlacingOrder = false
    @Published var alert: AlertBinder?

    private let transitionsLoader: () async throws -> TangemPayTariffPlanTransitionsResponse
    private let descriptionContext: DescriptionContext
    private let onSelectPlan: TangemPaySelectPlanAction?
    private weak var coordinator: TangemPaySelectPlanRoutable?

    private var transitions: TangemPayTariffPlanTransitionsResponse = []

    /// The change-plan entry point (Plan details) does not wire order placement yet, so the
    /// button stays disabled there. Onboarding injects the handler and enables it.
    /// [REDACTED_INFO]
    var isSelectEnabled: Bool {
        onSelectPlan != nil
    }

    var selectedPlan: Plan? {
        plans.first { $0.id == selectedPlanID } ?? plans.first
    }

    var selectedIndex: Int {
        plans.firstIndex { $0.id == selectedPlanID } ?? 0
    }

    var selectButtonTitle: String {
        switch selectedPlan?.transitionType {
        case .upgrade: Localization.tangempaySelectPlanBtnUpgrade
        case .downgrade: Localization.tangempaySelectPlanBtnDowngrade
        case .activation, .none: Localization.tangempaySelectPlanBtnSelect
        }
    }

    init(
        transitionsLoader: @escaping () async throws -> TangemPayTariffPlanTransitionsResponse,
        descriptionContext: DescriptionContext,
        onSelectPlan: TangemPaySelectPlanAction? = nil,
        coordinator: TangemPaySelectPlanRoutable?
    ) {
        self.transitionsLoader = transitionsLoader
        self.descriptionContext = descriptionContext
        self.onSelectPlan = onSelectPlan
        self.coordinator = coordinator
    }

    @MainActor
    func loadTransitions() async {
        isLoading = true
        do {
            let transitions = try await transitionsLoader()
            apply(transitions: transitions)
            isLoading = false
        } catch {
            isLoading = false
            alert = makeLoadingFailedAlert()
        }
    }

    func select() {
        guard let onSelectPlan, let plan = selectedPlan, !isPlacingOrder else {
            return
        }

        isPlacingOrder = true

        runTask(in: self) { @MainActor viewModel in
            do {
                try await onSelectPlan(plan.id, plan.transitionType)
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

    func comparePlans() {
        coordinator?.openComparePlans(transitions: transitions)
    }

    func close() {
        coordinator?.closeSelectPlanFlow()
    }
}

private extension TangemPaySelectPlanViewModel {
    func apply(transitions: TangemPayTariffPlanTransitionsResponse) {
        self.transitions = transitions
        plans = transitions.map { transition in
            Plan(
                id: transition.tariffPlan.id,
                name: transition.tariffPlan.name,
                imageURL: transition.tariffPlan.images.first { $0.type == .main }?.url,
                transitionType: transition.type,
                points: Self.makePoints(from: transition.tariffPlan.descriptionItems, context: descriptionContext)
            )
        }
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
        from items: [VisaCustomerInfoResponse.TariffPlan.DescriptionItem],
        context: DescriptionContext
    ) -> [Point] {
        items
            .filter { context.itemTypes.contains($0.type) }
            .sorted { ($0.type.sortIndex, $0.order) < ($1.type.sortIndex, $1.order) }
            .map { Point(title: $0.title, subtitle: $0.body) }
    }
}

private extension VisaCustomerInfoResponse.TariffPlan.DescriptionItem.ItemType {
    var sortIndex: Int {
        switch self {
        case .cardRelated: 0
        case .planRelated: 1
        case .onboardingRelated: 2
        }
    }
}

// MARK: - Types

extension TangemPaySelectPlanViewModel {
    enum DescriptionContext {
        case onboarding
        case planChange

        var itemTypes: Set<VisaCustomerInfoResponse.TariffPlan.DescriptionItem.ItemType> {
            switch self {
            case .onboarding: [.onboardingRelated]
            case .planChange: [.cardRelated, .planRelated]
            }
        }
    }

    struct Plan: Identifiable {
        let id: String
        let name: String
        let imageURL: String?
        let transitionType: TangemPayTariffPlanTransition.TransitionType
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
    func openComparePlans(transitions: TangemPayTariffPlanTransitionsResponse)
}
