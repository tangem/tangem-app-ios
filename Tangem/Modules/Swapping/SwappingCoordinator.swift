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

    @Published var swappingTokenListViewModel: SwappingTokenListViewModel?
    @Published var swappingPermissionViewModel: SwappingPermissionViewModel?
    @Published var successSwappingViewModel: SuccessSwappingViewModel?

    // MARK: - Child view models

    // MARK: - Properties

    private let factory = DependenciesFactory()

    required init(
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = SwappingConfigurator(factory: factory).createModule(input: options.input, coordinator: self)
    }
}

// MARK: - Options

extension SwappingCoordinator {
    struct Options {
        let input: SwappingConfigurator.InputModel
    }
}

// MARK: - SwappingRoutable

extension SwappingCoordinator: SwappingRoutable {
    func presentSwappingTokenList(sourceCurrency: Currency, userCurrencies: [Currency]) {
        swappingTokenListViewModel = SwappingTokenListViewModel(
            sourceCurrency: sourceCurrency,
            userCurrencies: userCurrencies,
            tokenIconURLBuilder: factory.createTokenIconURLBuilder(),
            currencyMapper: factory.createCurrencyMapper(),
            coordinator: self
        )
    }

    func presentPermissionView(inputModel: SwappingPermissionInputModel, transactionSender: TransactionSendable) {
        UIApplication.shared.endEditing()
        swappingPermissionViewModel = SwappingPermissionViewModel(
            inputModel: inputModel,
            transactionSender: transactionSender,
            coordinator: self
        )
    }

    func presentSuccessView(source: CurrencyAmount, result: CurrencyAmount) {
        successSwappingViewModel = SuccessSwappingViewModel(
            sourceCurrencyAmount: source,
            resultCurrencyAmount: result,
            coordinator: self
        )
    }
}

// MARK: - SwappingTokenListRoutable

extension SwappingCoordinator: SwappingTokenListRoutable {
    func userDidTap(currency: Currency) {
        swappingTokenListViewModel = nil
        rootViewModel?.userDidRequestChangeDestination(to: currency)
    }
}

// MARK: - SuccessSwappingRoutable

extension SwappingCoordinator: SuccessSwappingRoutable {
    func didTapMainButton() {
        successSwappingViewModel = nil
        dismiss()
    }
}

// MARK: - SwappingPermissionRoutable

extension SwappingCoordinator: SwappingPermissionRoutable {
    func didSendApproveTransaction() {
        swappingPermissionViewModel = nil
        rootViewModel?.didSendApproveTransaction()
    }

    func userDidCancel() {
        swappingPermissionViewModel = nil
    }
}
