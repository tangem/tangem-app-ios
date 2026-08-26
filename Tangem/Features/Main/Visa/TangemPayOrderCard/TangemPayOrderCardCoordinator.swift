//
//  TangemPayOrderCardCoordinator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

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
            issueFeeText: options.issueFeeText,
            virtualCardImageURL: options.virtualCardImageURL,
            countryName: options.countryName,
            selectedCardType: options.selectedCardType ?? .virtual,
            coordinator: self
        )
    }
}

// MARK: - Options

extension TangemPayOrderCardCoordinator {
    struct Options {
        let issueFeeText: String
        let virtualCardImageURL: URL?
        let nameOnCard: String?
        let countryName: String?
        let email: String?
        let phoneMask: String?
        let selectedCardType: TangemPayOrderCardType?
        weak var parentCoordinator: (any TangemPayOrderCardFlowRoutable)?
    }
}

// MARK: - TangemPayOrderCardTypeRoutable

extension TangemPayOrderCardCoordinator: TangemPayOrderCardTypeRoutable {
    func orderCardTypeDidSelectVirtual() {
        options?.parentCoordinator?.orderCardFlowDidSelectVirtual()
    }

    func orderCardTypeDidSelectPlastic() {
        orderCardDataViewModel = TangemPayOrderCardDataViewModel(
            nameOnCard: options?.nameOnCard,
            countryName: options?.countryName,
            email: options?.email,
            phoneMask: options?.phoneMask,
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
        // The order completes on a timer, so the form can be gone by the time it lands.
        guard orderCardDataViewModel != nil else { return }

        options?.parentCoordinator?.orderCardFlowDidOrderPlastic(email: options?.email)

        orderCardSuccessViewModel = TangemPayOrderCardSuccessViewModel(
            email: options?.email ?? "",
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
