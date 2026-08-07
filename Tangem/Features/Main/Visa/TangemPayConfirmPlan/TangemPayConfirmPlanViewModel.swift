//
//  TangemPayConfirmPlanViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemPay
import struct TangemUIUtils.AlertBinder

final class TangemPayConfirmPlanViewModel: ObservableObject {
    let cardImageURL: String?
    let title: String
    let points: [Point]
    let confirmButtonTitle: String

    @Published private(set) var isProcessing = false
    @Published var alert: AlertBinder?

    private let targetPlanId: String
    private let targetPlanType: String
    private let transitionType: TangemPayTariffPlanTransition.TransitionType
    private let tariffPlanSelector: any TangemPayTariffPlanSelector
    private weak var coordinator: TangemPayConfirmPlanRoutable?

    init(
        transitionType: TangemPayTariffPlanTransition.TransitionType,
        targetPlan: VisaCustomerInfoResponse.TariffPlan,
        currentPlan: VisaCustomerInfoResponse.TariffPlan,
        nextBillingAt: Date?,
        tariffPlanSelector: any TangemPayTariffPlanSelector,
        coordinator: TangemPayConfirmPlanRoutable?
    ) {
        targetPlanId = targetPlan.id
        targetPlanType = targetPlan.type
        self.transitionType = transitionType
        self.tariffPlanSelector = tariffPlanSelector
        self.coordinator = coordinator

        cardImageURL = targetPlan.images.first { $0.type == .main }?.url

        switch transitionType {
        case .downgrade:
            let date = Self.formattedDate(nextBillingAt)
            title = Localization.tangempaySelectPlanConfirmDowngradeTitle(currentPlan.name, currentPlan.programName, date)
            points = [
                Point(Localization.tangempaySelectPlanConfirmPointMoveOnDate(date, targetPlan.name)),
                Point(Localization.tangempaySelectPlanConfirmPointCardsClosed(currentPlan.programName)),
                Point(Localization.tangempaySelectPlanConfirmPointCancelTill(date)),
                Point(Localization.tangempaySelectPlanConfirmPointNoFee),
            ]
            confirmButtonTitle = Localization.tangempaySelectPlanBtnDowngrade

        case .upgrade, .activation:
            title = Localization.tangempaySelectPlanConfirmUpgradeTitle(targetPlan.programName)
            points = [
                Point(Localization.tangempaySelectPlanConfirmPointVirtualCard(targetPlan.programName)),
                Point(Localization.tangempaySelectPlanConfirmPointMonthlyFee(Self.formattedRecurringFee(targetPlan))),
            ]
            confirmButtonTitle = Localization.tangempaySelectPlanBtnUpgrade
        }
    }

    func onAppear() {
        Analytics.log(event: .visaTiersPlanChangeConfirmationScreenShowed, params: [.plan: targetPlanType])
    }

    func confirm() {
        guard !isProcessing else { return }

        switch transitionType {
        case .upgrade, .activation:
            Analytics.log(.visaTiersPlanChangeUpgradeClicked)
        case .downgrade:
            break
        }

        isProcessing = true

        runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.tariffPlanSelector.selectTariffPlan(
                    targetTariffPlanId: viewModel.targetPlanId,
                    transitionType: viewModel.transitionType
                )
                viewModel.coordinator?.confirmPlanDidComplete(transitionType: viewModel.transitionType)
            } catch {
                viewModel.isProcessing = false
                viewModel.alert = AlertBinder(
                    title: Localization.commonError,
                    message: Localization.commonUnknownError
                )
            }
        }
    }

    func cancel() {
        Analytics.log(.visaTiersPlanChangeCancelClicked)
        coordinator?.closeConfirmPlan()
    }

    func close() {
        coordinator?.closeSelectPlanFlow()
    }
}

// MARK: - Formatting

private extension TangemPayConfirmPlanViewModel {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return dateFormatter.string(from: date)
    }

    static func formattedRecurringFee(_ plan: VisaCustomerInfoResponse.TariffPlan) -> String {
        guard let fee = plan.fees.first(where: { $0.type == .recurring }) else { return "" }
        return BalanceFormatter().formatFiatBalance(fee.amount, currencyCode: fee.currency)
    }
}

// MARK: - Types

extension TangemPayConfirmPlanViewModel {
    struct Point: Identifiable {
        let id = UUID()
        let text: String

        init(_ text: String) {
            self.text = text
        }
    }
}

// MARK: - Routable

protocol TangemPayConfirmPlanRoutable: AnyObject {
    func closeConfirmPlan()
    func closeSelectPlanFlow()
    func confirmPlanDidComplete(transitionType: TangemPayTariffPlanTransition.TransitionType)
}
