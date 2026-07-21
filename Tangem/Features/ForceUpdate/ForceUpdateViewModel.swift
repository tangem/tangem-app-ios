//
//  ForceUpdateViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemUI
import TangemLocalization

final class ForceUpdateViewModel {
    @Injected(\.forceUpdateService) private var forceUpdateService: ForceUpdateService

    private let reason: ForceUpdateReason

    private weak var coordinator: ForceUpdateRoutable?

    private var subscription: AnyCancellable?

    init(reason: ForceUpdateReason, coordinator: ForceUpdateRoutable?) {
        self.reason = reason
        self.coordinator = coordinator
        bind()
    }

    deinit {
        AppLogger.debug("ForceUpdateViewModel deinit")
    }

    private func bind() {
        subscription = forceUpdateService
            .statePublisher
            .map(\.forceUpdateReason)
            .filter { $0 == nil }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.coordinator?.closeForceUpdate()
            }
    }

    var title: String {
        switch reason {
        case .requiresAppUpdate:
            return Localization.forceUpdateWarningTitle
        case .requiresOSUpdate:
            return Localization.forceUpdateOsTitle
        case .brick:
            return Localization.forceUpdateBrickTitle
        }
    }

    var subtitle: String {
        switch reason {
        case .requiresAppUpdate:
            return Localization.forceUpdateWarningMessage
        case .requiresOSUpdate:
            return Localization.forceUpdateOsDescription
        case .brick:
            return Localization.forceUpdateBrickDescription
        }
    }

    var primaryButtonSettings: MainButton.Settings? {
        switch reason {
        case .requiresAppUpdate:
            return MainButton.Settings(
                title: Localization.forceUpdateButton,
                style: .primary,
                size: .default,
                action: openAppStore
            )
        case .requiresOSUpdate:
            // Soft warning — let the user acknowledge and continue into the app.
            return MainButton.Settings(
                title: Localization.commonLater,
                style: .primary,
                size: .default,
                action: dismissOSWarning
            )
        case .brick:
            return nil
        }
    }

    var supportButtonSettings: MainButton.Settings? {
        guard reason == .brick else {
            return nil
        }

        return MainButton.Settings(
            title: Localization.commonContactSupport,
            style: .secondary,
            size: .default,
            action: openSupport
        )
    }

    func onAppear() {
        forceUpdateService.refreshAndApply()
    }

    private func openAppStore() {
        AppStoreOpener.open()
    }

    private func openSupport() {
        coordinator?.openSupport()
    }

    private func dismissOSWarning() {
        forceUpdateService.dismissOSUpdateWarning()
        coordinator?.closeForceUpdate()
    }
}
