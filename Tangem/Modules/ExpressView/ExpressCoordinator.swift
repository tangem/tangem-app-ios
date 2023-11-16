//
//  ExpressCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping
import UIKit

class ExpressCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: ExpressViewModel?

    // MARK: - Child coordinators

    @Published var swappingSuccessCoordinator: SwappingSuccessCoordinator?

    // MARK: - Child view models

    @Published var swappingTokenListViewModel: SwappingTokenListViewModel?
    @Published var expressFeeSelectorViewModel: ExpressFeeBottomSheetViewModel?
    @Published var swappingApproveViewModel: SwappingApproveViewModel?

    // MARK: - Properties

    private let factory: SwappingModulesFactory

    required init(
        factory: SwappingModulesFactory,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.factory = factory
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = factory.makeExpressViewModel(coordinator: self)
    }
}

// MARK: - Options

extension ExpressCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - ExpressRoutable

extension ExpressCoordinator: ExpressRoutable {
    func presentSwappingTokenList(sourceCurrency: Currency) {
        UIApplication.shared.endEditing()
        Analytics.log(.swapChooseTokenScreenOpened)
        swappingTokenListViewModel = factory.makeSwappingTokenListViewModel(coordinator: self)
    }

    func presentFeeSelectorView() {
        expressFeeSelectorViewModel = factory.makeExpressFeeSelectorViewModel(coordinator: self)
    }

    func presentApproveView() {
        UIApplication.shared.endEditing()
        swappingApproveViewModel = factory.makeSwappingApproveViewModel(coordinator: self)
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

extension ExpressCoordinator: SwappingTokenListRoutable {
    func userDidTap(currency: Currency) {
        swappingTokenListViewModel = nil
        rootViewModel?.userDidRequestChangeDestination(to: currency)
    }
}

// MARK: - ExpressRoutable

extension ExpressCoordinator: ExpressFeeBottomSheetRoutable {
    func closeExpressFeeBottomSheet() {
        expressFeeSelectorViewModel = nil
    }
}

// MARK: -  SwappingApproveRoutable

extension ExpressCoordinator: SwappingApproveRoutable {
    func didSendApproveTransaction(transactionData: SwappingTransactionData) {
        swappingApproveViewModel = nil
    }

    func userDidCancel() {
        swappingApproveViewModel = nil
        rootViewModel?.didCloseApproveSheet()
    }
}
