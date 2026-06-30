//
//  ForceUpdateViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI
import TangemLocalization

final class ForceUpdateViewModel {
    @Injected(\.forceUpdateService) private var forceUpdateService: ForceUpdateService

    let reason: ForceUpdateReason

    weak var coordinator: ForceUpdateRoutable?

    init(reason: ForceUpdateReason, coordinator: ForceUpdateRoutable?) {
        self.reason = reason
        self.coordinator = coordinator
    }

    deinit {
        AppLogger.debug("ForceUpdateViewModel deinit")
    }

    var title: String {
        switch reason {
        case .requiresAppUpdate:
            return Localization.forceUpdateWarningTitle
        case .requiresOSUpdate:
            // [REDACTED_TODO_COMMENT]
            return "OS Update Required"
        case .brick:
            // [REDACTED_TODO_COMMENT]
            return "App No Longer Supported"
        }
    }

    var subtitle: String {
        switch reason {
        case .requiresAppUpdate:
            return Localization.forceUpdateWarningMessage
        case .requiresOSUpdate:
            // [REDACTED_TODO_COMMENT]
            return "Please update your operating system to continue using the application."
        case .brick:
            // [REDACTED_TODO_COMMENT]
            return "This device can no longer run the application. Please use a supported device."
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
        case .requiresOSUpdate, .brick:
            return nil
        }
    }

    func onAppear() {
        forceUpdateService.refreshAndApply()
    }

    func openAppStore() {
        coordinator?.openAppStore()
    }
}
