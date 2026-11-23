//
//  TangemPayVerifiedCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay
import TangemUI

final class TangemPayVerifiedCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissReason>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var verifiedViewModel: TangemPayVerifiedViewModel?
    @Published private(set) var successViewModel: TangemPayOnboardingSuccessViewModel?
    @Published var selectPlanCoordinator: TangemPaySelectPlanCoordinator?

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

        verifiedViewModel = TangemPayVerifiedViewModel(
            interactor: options.interactor,
            addressSigner: options.userWalletModel.tangemPayBankingAccountAddressSigner,
            signingType: SigningActionButtonViewTypeBuilder().build(config: options.userWalletModel.config),
            coordinator: self
        )
    }
}

// MARK: - Options

extension TangemPayVerifiedCoordinator {
    struct Options {
        let interactor: any TangemPayUnifiedOnboardingInteractor
        let userWalletModel: any UserWalletModel
    }

    enum DismissReason {
        case onboardingOrderPlaced
        case closed
    }
}

// MARK: - TangemPayVerifiedRoutable

extension TangemPayVerifiedCoordinator: TangemPayVerifiedRoutable {
    func openSelectPlan(products: TangemPayProductsAvailability) {
        guard let options else {
            return
        }

        let coordinator = TangemPaySelectPlanCoordinator(
            dismissAction: { [weak self] reason in
                self?.selectPlanCoordinator = nil

                switch reason {
                case .planUpgraded:
                    self?.onboardingOrderDidPlace()
                case .planDowngraded, .closed:
                    break
                }
            },
            popToRootAction: popToRootAction
        )
        coordinator.start(
            with: .init(
                tariffPlanSelector: options.interactor,
                mode: .createOnboardingOrder(
                    products: products,
                    interactor: options.interactor,
                    addressSigner: options.userWalletModel.tangemPayBankingAccountAddressSigner,
                    signingType: SigningActionButtonViewTypeBuilder().build(config: options.userWalletModel.config)
                )
            )
        )
        selectPlanCoordinator = coordinator
    }

    func onboardingOrderDidPlace() {
        successViewModel = TangemPayOnboardingSuccessViewModel(coordinator: self)
    }

    func closeVerifiedFlow() {
        dismiss(with: .closed)
    }
}

// MARK: - TangemPayOnboardingSuccessRoutable

extension TangemPayVerifiedCoordinator: TangemPayOnboardingSuccessRoutable {
    func closeOnboardingSuccess() {
        dismiss(with: .onboardingOrderPlaced)
    }
}
