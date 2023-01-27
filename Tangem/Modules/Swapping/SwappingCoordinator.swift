//
//  SwappingCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExchange
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

        swappingTokenListViewModel = factory.makeSwappingTokenListViewModel(coordinator: self)
    }

    func presentPermissionView(inputModel: SwappingPermissionInputModel, transactionSender: TransactionSendable) {
        UIApplication.shared.endEditing()
        swappingPermissionViewModel = factory.makeSwappingPermissionViewModel(inputModel: inputModel, coordinator: self)
    }

    func presentSuccessView(inputModel: SwappingSuccessInputModel) {
        UIApplication.shared.endEditing()

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

// MARK: - SwappingPermissionRoutable

extension SwappingCoordinator: SwappingPermissionRoutable {
    func didSendApproveTransaction(transactionInfo: ExchangeTransactionDataModel) {
        swappingPermissionViewModel = nil
        rootViewModel?.didSendApproveTransaction(transactionInfo: transactionInfo)
    }

    func userDidCancel() {
        swappingPermissionViewModel = nil
    }
}
