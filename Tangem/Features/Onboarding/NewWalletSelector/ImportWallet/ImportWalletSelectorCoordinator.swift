//
//  ImportWalletSelectorCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemUIUtils

class ImportWalletSelectorCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var importViewModel: ImportWalletSelectorViewModel?
    @Published var mailViewModel: MailViewModel?
    @Published var isScanning: Bool = false

    @Published var onboardingCoordinator: OnboardingCoordinator?

    @Published var actionSheet: ActionSheetBinder?
    @Published var error: AlertBinder?

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.safariManager) private var safariManager: SafariManager

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: InputOptions) {
        importViewModel = ImportWalletSelectorViewModel(coordinator: self)
    }
}

// MARK: - ImportWalletSelectorRoutable

extension ImportWalletSelectorCoordinator: ImportWalletSelectorRoutable {
    func openOnboarding(options: OnboardingCoordinator.Options) {
        openOnboarding(inputOptions: options)
    }

    func openMain(userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }
}

// MARK: - Navigation

private extension ImportWalletSelectorCoordinator {
    func openOnboarding(inputOptions: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.openMain(userWalletModel: userWalletModel)
            case .dismiss:
                self?.onboardingCoordinator = nil
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        onboardingCoordinator = coordinator
    }
}

// MARK: - Options

extension ImportWalletSelectorCoordinator {
    struct InputOptions {}

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
    }
}
