//
//  ForceUpdateViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemFoundation
import TangemAssets
import TangemUI
import TangemLocalization

final class ForceUpdateViewModel {
    @Injected(\.forceUpdateService) private var forceUpdateService: ForceUpdateService

    private let reason: ForceUpdateReason
    private let analyticsLogger: ForceUpdateAnalyticsLogger

    private weak var coordinator: ForceUpdateRoutable?

    private var subscription: AnyCancellable?

    init(reason: ForceUpdateReason, analyticsLogger: ForceUpdateAnalyticsLogger, coordinator: ForceUpdateRoutable?) {
        self.reason = reason
        self.analyticsLogger = analyticsLogger
        self.coordinator = coordinator
        bind()
        analyticsLogger.logScreenShown(reason: reason)
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

    // MARK: - Presentation

    var icon: ImageType {
        switch reason {
        case .requiresAppUpdate, .brick:
            return DesignSystem.Icons.Error.filled28
        case .requiresOSUpdate:
            return DesignSystem.Icons.Warning.filled28
        }
    }

    var accentColor: Color {
        switch reason {
        case .requiresAppUpdate, .brick:
            return DesignSystem.Color.iconStatusError
        case .requiresOSUpdate:
            return DesignSystem.Color.iconStatusWarning
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

    /// The bottom (filled) button. Absent on the OS-update screen, which only offers "Later".
    var primaryButton: ButtonModel? {
        switch reason {
        case .requiresAppUpdate:
            return ButtonModel(title: Localization.forceUpdateAction, style: .primary) { [weak self] in
                self?.openAppStore()
            }
        case .requiresOSUpdate:
            return nil
        case .brick:
            return ButtonModel(title: Localization.commonContactSupport, style: .primary) { [weak self] in
                self?.openSupport(source: .unsupportedDevice)
            }
        }
    }

    /// The top (outlined) button. Absent on the BRICK screen, which offers a single action.
    var secondaryButton: ButtonModel? {
        switch reason {
        case .requiresAppUpdate:
            return ButtonModel(title: Localization.commonContactSupport, style: .secondary(.default)) { [weak self] in
                self?.openSupport(source: .criticalUpdate)
            }
        case .requiresOSUpdate:
            return ButtonModel(title: Localization.commonLater, style: .secondary(.default)) { [weak self] in
                self?.dismissOSWarning()
            }
        case .brick:
            return nil
        }
    }

    func onAppear() {
        forceUpdateService.refreshAndApply()
    }

    private func openAppStore() {
        analyticsLogger.logUpdateNowTapped()
        coordinator?.openAppStore()
    }

    private func openSupport(source: ForceUpdateSupportSource) {
        analyticsLogger.logContactSupportTapped(source: source)
        coordinator?.openSupport()
    }

    private func dismissOSWarning() {
        analyticsLogger.logLaterTapped()
        forceUpdateService.dismissOSUpdateWarning()
        coordinator?.closeForceUpdate()
    }
}

// MARK: - ButtonModel

extension ForceUpdateViewModel {
    struct ButtonModel {
        let title: String
        let style: TangemUI.Button.StyleType
        let action: () -> Void
    }
}
