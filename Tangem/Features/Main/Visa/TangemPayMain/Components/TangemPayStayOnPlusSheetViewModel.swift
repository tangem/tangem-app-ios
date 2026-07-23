//
//  TangemPayStayOnPlusSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemVisa

protocol TangemPayStayOnPlusSheetRoutable: AnyObject {
    func stayOnCurrentPlan() async throws
    func closeStayOnPlusSheet()
}

final class TangemPayStayOnPlusSheetViewModel: TangemPayPopupViewModel {
    var icon: Image {
        DesignSystem.Icons.Heart.regular28.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .info
    }

    var title: AttributedString {
        .init(Localization.tangempayCurrentPlanStaySheetTitle(planName))
    }

    var description: AttributedString {
        .init(Localization.tangempayCurrentPlanStaySheetBody(pendingPlanName))
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.tangempayCurrentPlanStayButton(planName),
            style: .primary,
            size: .default,
            isLoading: isLoading,
            action: confirm
        )
    }

    var secondaryButton: MainButton.Settings? {
        MainButton.Settings(
            title: Localization.commonCancel,
            style: .secondary,
            size: .default,
            action: dismiss
        )
    }

    @Published private(set) var isLoading = false

    private let planName: String
    private let pendingPlanName: String
    private weak var coordinator: TangemPayStayOnPlusSheetRoutable?

    init(
        planName: String,
        pendingPlanName: String,
        coordinator: TangemPayStayOnPlusSheetRoutable?
    ) {
        self.planName = planName
        self.pendingPlanName = pendingPlanName
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeStayOnPlusSheet()
    }
}

// MARK: - Private

private extension TangemPayStayOnPlusSheetViewModel {
    func confirm() {
        guard !isLoading else { return }

        isLoading = true

        runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.coordinator?.stayOnCurrentPlan()
            } catch {
                VisaLogger.error("Failed to cancel pending tariff plan transition", error: error)
            }

            viewModel.isLoading = false
            viewModel.dismiss()
        }
    }
}
