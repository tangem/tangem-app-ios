//
//  PromotionCoordinator.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Combine

class PromotionCoordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    private weak var output: PromotionOutput?

    // MARK: - Root view model

    @Published private(set) var rootViewModel: PromotionViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    required init(
        output: PromotionOutput,
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.output = output
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = PromotionViewModel(options: options, coordinator: self)
    }
}

// MARK: - Options

extension PromotionCoordinator {
    enum Options {
        case `default`
        case newUser
        case oldUser(cardPublicKey: String, cardId: String, walletId: String)
    }
}

// MARK: - LearnRoutable

extension PromotionCoordinator: PromotionRoutable {
    func startAwardProcess() {
        output?.startAwardProcess()
        dismissAction()
    }

    func closeModule() {
        dismissAction()
    }
}
