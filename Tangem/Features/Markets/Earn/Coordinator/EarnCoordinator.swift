//
//  EarnCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUIUtils.AlertBinder

final class EarnCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published var rootViewModel: EarnDetailViewModel?
    @Published var error: AlertBinder?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            rootViewModel = EarnDetailViewModel(
                coordinator: self
            )
        }
    }
}

// MARK: - Options

extension EarnCoordinator {
    struct Options {}
}

// MARK: - EarnDetailRoutable

extension EarnCoordinator: EarnDetailRoutable {
    func dismiss() {
        dismissAction(())
    }

    func openEarnTokenDetails(for token: EarnTokenModel) {
        // Will be implemented in future iteration
    }
}
