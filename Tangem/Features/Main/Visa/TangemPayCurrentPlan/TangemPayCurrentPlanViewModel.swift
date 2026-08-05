//
//  TangemPayCurrentPlanViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUIUtils

final class TangemPayCurrentPlanViewModel: ObservableObject {
    let planName: String
    let sections: [Section]
    let changePlanButtonTitle: String

    @Published private(set) var downgradeBanner: DowngradeBanner?
    @Published private(set) var feeChargedBannerText: String?
    @Published private(set) var awaitingDepositBanner: AwaitingDepositBanner?
    @Published private(set) var isPlanChangeAvailable: Bool
    @Published private(set) var isCancellingTransition = false
    @Published var alert: AlertBinder?

    private let userWalletId: UserWalletId
    private let awaitingDepositCanceller: any TangemPayAwaitingDepositCanceller
    private weak var coordinator: TangemPayCurrentPlanRoutable?

    init(
        userWalletId: UserWalletId,
        customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan,
        customerTariffPlanPublisher: AnyPublisher<VisaCustomerInfoResponse.CustomerTariffPlan?, Never>,
        awaitingDepositCanceller: any TangemPayAwaitingDepositCanceller,
        coordinator: TangemPayCurrentPlanRoutable? = nil
    ) {
        self.userWalletId = userWalletId
        self.awaitingDepositCanceller = awaitingDepositCanceller
        self.coordinator = coordinator

        let tariffPlan = customerTariffPlan.tariffPlan
        planName = tariffPlan.name
        sections = Self.makeSections(from: tariffPlan.descriptionItems)
        downgradeBanner = Self.makeDowngradeBanner(from: customerTariffPlan)
        feeChargedBannerText = Self.makeFeeChargedBannerText(from: customerTariffPlan)
        isPlanChangeAvailable = customerTariffPlan.status != .transitioning

        changePlanButtonTitle = Localization.tangempayCurrentPlanChange

        customerTariffPlanPublisher
            .map { $0.flatMap(Self.makeDowngradeBanner(from:)) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$downgradeBanner)

        customerTariffPlanPublisher
            .map { $0.flatMap(Self.makeFeeChargedBannerText(from:)) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$feeChargedBannerText)

        awaitingDepositCanceller.awaitingDepositInfoPublisher
            .map { $0.map(Self.makeAwaitingDepositBanner(from:)) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$awaitingDepositBanner)

        Publishers.CombineLatest(
            customerTariffPlanPublisher,
            awaitingDepositCanceller.awaitingDepositInfoPublisher
        )
        .map { plan, awaitingDepositInfo in
            awaitingDepositInfo == nil && plan?.status != .transitioning
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .assign(to: &$isPlanChangeAvailable)
    }

    func changePlan() {
        Analytics.log(.visaTiersChangePlanClicked)
        coordinator?.openSelectPlan()
    }

    func onAwaitingDepositBannerAppear() {
        Analytics.log(.visaTiersTopupBannerForPlusShowed, contextParams: .userWallet(userWalletId))
    }

    func cancelTransition() {
        guard !isCancellingTransition, awaitingDepositBanner != nil else {
            return
        }

        Analytics.log(.visaTiersCancelPlusMoveToBasicClicked, contextParams: .userWallet(userWalletId))

        isCancellingTransition = true

        runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.awaitingDepositCanceller.cancelAwaitingDepositOrder()

                viewModel.isCancellingTransition = false
            } catch {
                viewModel.alert = AlertBinder(
                    title: Localization.commonSomethingWentWrong,
                    message: Localization.commonTryAgainLater
                )

                viewModel.isCancellingTransition = false
            }
        }
    }

    func stayOnPlus() {
        guard let downgradeBanner else {
            return
        }

        Analytics.log(.visaTiersStayOnPlusConditionsClicked)

        coordinator?.openStayOnPlusConfirmation(
            planName: downgradeBanner.planName,
            pendingPlanName: downgradeBanner.pendingPlanName
        )
    }
}

// MARK: - Mapping

private extension TangemPayCurrentPlanViewModel {
    static let downgradeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static func makeDowngradeBanner(
        from customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan
    ) -> DowngradeBanner? {
        guard
            customerTariffPlan.status == .downgradePending,
            let pendingPlan = customerTariffPlan.pendingTariffPlan,
            let nextBillingAt = customerTariffPlan.nextBillingAt
        else {
            return nil
        }

        let planName = customerTariffPlan.tariffPlan.name
        let fee = customerTariffPlan.tariffPlan.fees
            .first { $0.type == .recurring }
            .map { BalanceFormatter().formatFiatBalance($0.amount, currencyCode: $0.currency) } ?? ""

        let text = Localization.tangempayCurrentPlanActiveTillNotification(
            planName,
            downgradeDateFormatter.string(from: nextBillingAt),
            pendingPlan.name,
            fee
        )

        return DowngradeBanner(text: text, planName: planName, pendingPlanName: pendingPlan.name)
    }

    static func makeAwaitingDepositBanner(from info: TangemPayAwaitingDepositInfo) -> AwaitingDepositBanner {
        AwaitingDepositBanner(
            text: Localization.tangempayCurrentPlanAwaitingDepositNotification(info.planName),
            cancelButtonTitle: Localization.tangempayCardDetailsAwaitingDepositCancelButton(info.planName, info.fallbackPlanName)
        )
    }

    static func makeFeeChargedBannerText(
        from customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan
    ) -> String? {
        guard
            customerTariffPlan.status == .active,
            let nextBillingAt = customerTariffPlan.nextBillingAt,
            let recurringFee = customerTariffPlan.tariffPlan.fees.first(where: { $0.type == .recurring })
        else {
            return nil
        }

        let fee = BalanceFormatter().formatFiatBalance(recurringFee.amount, currencyCode: recurringFee.currency)

        return Localization.tangempayCurrentPlanFeeChargedNotification(fee, downgradeDateFormatter.string(from: nextBillingAt))
    }

    static func makeSections(
        from items: [VisaCustomerInfoResponse.TariffPlan.DescriptionItem]
    ) -> [Section] {
        let grouped = Dictionary(grouping: items, by: \.type)
        let orderedSections: [VisaCustomerInfoResponse.TariffPlan.DescriptionItem.ItemType] = [.cardRelated, .planRelated]

        return orderedSections.compactMap { type in
            guard let sectionItems = grouped[type], !sectionItems.isEmpty else {
                return nil
            }

            let rows = sectionItems
                .sorted { $0.order < $1.order }
                .map { Row(label: $0.title, value: $0.body ?? "") }

            return Section(title: type.sectionTitle, rows: rows)
        }
    }
}

private extension VisaCustomerInfoResponse.TariffPlan.DescriptionItem.ItemType {
    var sectionTitle: String {
        switch self {
        case .cardRelated: Localization.tangempayCurrentPlanSectionCard
        case .planRelated: Localization.tangempayCurrentPlanSectionPlan
        case .onboardingRelated: ""
        }
    }
}

// MARK: - Routable

protocol TangemPayCurrentPlanRoutable: AnyObject {
    func openSelectPlan()
    func openStayOnPlusConfirmation(planName: String, pendingPlanName: String)
}

extension TangemPayCurrentPlanViewModel {
    struct DowngradeBanner: Equatable {
        let text: String
        let planName: String
        let pendingPlanName: String
    }

    struct AwaitingDepositBanner: Equatable {
        let text: String
        let cancelButtonTitle: String
    }

    struct Section: Identifiable {
        let id = UUID()
        let title: String
        let rows: [Row]
    }

    struct Row: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }
}
