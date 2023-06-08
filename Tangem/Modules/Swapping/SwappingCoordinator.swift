//
//  SwappingCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping
import UIKit

class SwappingCoordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SwappingViewModel?

    // MARK: - Child coordinators

    @Published var swappingSuccessCoordinator: SwappingSuccessCoordinator?

    // MARK: - Child view models

    @Published var swappingTokenListViewModel: SwappingTokenListViewModel?
    @Published var swappingPermissionViewModel: SwappingPermissionViewModel?
    @Published var swappingApproveViewModel: SwappingApproveViewModel?

    // MARK: - Properties

    private let factory: SwappingModulesFactory

    required init(
        factory: SwappingModulesFactory,
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.factory = factory
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = factory.makeSwappingViewModel(coordinator: self)
    }
}

// MARK: - Options

extension SwappingCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - SwappingRoutable

extension SwappingCoordinator: SwappingRoutable {
    func presentSwappingTokenList(sourceCurrency: Currency) {
        UIApplication.shared.endEditing()
        Analytics.log(.swapChooseTokenScreenOpened)
        swappingTokenListViewModel = factory.makeSwappingTokenListViewModel(coordinator: self)
    }

    func presentPermissionView(inputModel: SwappingPermissionInputModel, transactionSender: SwappingTransactionSender) {
        UIApplication.shared.endEditing()

        if FeatureProvider.isAvailable(.abilityChooseApproveAmount) {
            swappingApproveViewModel = factory.makeSwappingApproveViewModel(coordinator: self)
        } else {
            swappingPermissionViewModel = factory.makeSwappingPermissionViewModel(inputModel: inputModel, coordinator: self)
        }
    }

    func presentSuccessView(inputModel: SwappingSuccessInputModel) {
        UIApplication.shared.endEditing()
        Analytics.log(.swapSwapInProgressScreenOpened)

        let dismissAction = { [weak self] in
            self?.swappingSuccessCoordinator = nil
            DispatchQueue.main.async {
                self?.dismiss()
            }
        }

        let coordinator = SwappingSuccessCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(inputModel: inputModel))

        swappingSuccessCoordinator = coordinator
    }
}

// MARK: - SwappingTokenListRoutable

extension SwappingCoordinator: SwappingTokenListRoutable {
    func userDidTap(currency: Currency) {
        swappingTokenListViewModel = nil
        rootViewModel?.userDidRequestChangeDestination(to: currency)
    }
}

// MARK: - SwappingPermissionRoutable, SwappingApproveRoutable

extension SwappingCoordinator: SwappingPermissionRoutable, SwappingApproveRoutable {
    func didSendApproveTransaction(transactionData: SwappingTransactionData) {
        swappingPermissionViewModel = nil
        swappingApproveViewModel = nil
    }

    func userDidCancel() {
        swappingPermissionViewModel = nil
        swappingApproveViewModel = nil
        rootViewModel?.didClosePermissionSheet()
    }
}
