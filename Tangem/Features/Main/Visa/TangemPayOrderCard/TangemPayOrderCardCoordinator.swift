//
//  TangemPayOrderCardCoordinator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class TangemPayOrderCardCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var orderCardTypeViewModel: TangemPayOrderCardTypeViewModel?

    // MARK: - Child view models (push navigation)

    @Published var orderCardDataViewModel: TangemPayOrderCardDataViewModel?
    @Published var orderCardSuccessViewModel: TangemPayOrderCardSuccessViewModel?

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

        orderCardTypeViewModel = TangemPayOrderCardTypeViewModel(
            virtualOffer: options.tangemPayAccount.additionalCardIssueOffer,
            plasticOffer: options.tangemPayAccount.plasticCardIssueOffer,
            tariffPlanCardImageURL: options.tariffPlanCardImageURL,
            availableBalancePublisher: options.availableBalancePublisher,
            countryName: options.countryName,
            selectedCardType: options.selectedCardType,
            coordinator: self
        )
    }
}

// MARK: - Options

extension TangemPayOrderCardCoordinator {
    struct Options {
        let tariffPlanCardImageURL: URL?
        let nameOnCard: String?
        let countryName: String?
        let email: String?
        let phoneMask: String?
        let availableBalancePublisher: AnyPublisher<Decimal?, Never>
        let selectedCardType: TangemPayOrderCardType?
        let tangemPayAccount: TangemPayAccount
        weak var parentCoordinator: (any TangemPayOrderCardFlowRoutable)?
    }
}

// MARK: - TangemPayOrderCardTypeRoutable

extension TangemPayOrderCardCoordinator: TangemPayOrderCardTypeRoutable {
    func orderCardTypeDidSelectVirtual() {
        options?.parentCoordinator?.orderCardFlowDidSelectVirtual()
    }

    func orderCardTypeDidSelectPlastic() {
        guard let options else { return }

        orderCardDataViewModel = TangemPayOrderCardDataViewModel(
            nameOnCard: options.nameOnCard,
            countryName: options.countryName,
            email: options.email,
            phoneMask: options.phoneMask,
            tangemPayAccount: options.tangemPayAccount,
            coordinator: self
        )
    }

    func closeOrderCardType() {
        dismiss()
    }
}

// MARK: - TangemPayOrderCardDataRoutable

extension TangemPayOrderCardCoordinator: TangemPayOrderCardDataRoutable {
    func orderCardDataDidPlaceOrder() {
        // The request outlives the form, which can be dismissed before it lands.
        guard orderCardDataViewModel != nil else { return }

        orderCardSuccessViewModel = TangemPayOrderCardSuccessViewModel(
            email: options?.email ?? "",
            deliveryEtaMaxDays: options?.tangemPayAccount.plasticCardIssueOffer?.data?.deliveryEtaMaxDays,
            coordinator: self
        )
    }

    func orderCardDataDidGoBack() {
        orderCardDataViewModel = nil
        orderCardSuccessViewModel = nil
    }

    func closeOrderCardData() {
        dismiss()
    }
}

// MARK: - TangemPayOrderCardSuccessRoutable

extension TangemPayOrderCardCoordinator: TangemPayOrderCardSuccessRoutable {
    func orderCardSuccessDidTapShowCard() {
        dismiss()
    }
}
