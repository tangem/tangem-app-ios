//
//  UncompletedBackupCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class UncompletedBackupCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: UncompletedBackupViewModel?

    // MARK: - Child coordinators

    @Published var modalOnboardingCoordinator: OnboardingCoordinator?

    // MARK: - Child view models

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options = .default) {
        rootViewModel = .init(coordinator: self)
    }
}

// MARK: - Options

extension UncompletedBackupCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - IncompleteBackupRoutable

extension UncompletedBackupCoordinator: UncompletedBackupRoutable {
    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] _ in
            self?.modalOnboardingCoordinator = nil
            self?.dismiss()
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options(input: input, destination: .dismiss)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }
}
