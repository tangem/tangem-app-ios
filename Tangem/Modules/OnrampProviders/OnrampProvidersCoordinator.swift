//
//  OnrampProvidersCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OnrampProvidersCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: OnrampProvidersViewModel?

    // MARK: - Child view models

    // [REDACTED_TODO_COMMENT]
    // Payment methods view

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = .init(coordinator: self)
    }
}

// MARK: - Options

extension OnrampProvidersCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - OnrampProvidersRoutable

extension OnrampProvidersCoordinator: OnrampProvidersRoutable {}
