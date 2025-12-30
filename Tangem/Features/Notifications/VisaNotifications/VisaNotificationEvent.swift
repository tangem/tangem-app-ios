//
//  VisaNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemFoundation
import TangemAssets
import TangemUI

enum VisaNotificationEvent {
    case error(UniversalError)
    case onboardingAccountActivationInfo
    case missingValidRefreshToken(icon: MainButton.Icon?)
}

extension VisaNotificationEvent {
    static func == (lhs: VisaNotificationEvent, rhs: VisaNotificationEvent) -> Bool {
        switch (lhs, rhs) {
        case (.onboardingAccountActivationInfo, .onboardingAccountActivationInfo): return true
        case (.missingValidRefreshToken, .missingValidRefreshToken): return true
        case (.error(let lhsError), .error(let rhsError)): return lhsError.errorCode == rhsError.errorCode
        case (.onboardingAccountActivationInfo, _), (.missingValidRefreshToken, _), (.error, _):
            return false
        }
    }
}

extension VisaNotificationEvent: NotificationEvent {
    var id: NotificationViewId {
        if case .error(let tangemError) = self {
            return tangemError.errorCode
        }

        var hasher = Hasher()
        hasher.combine(String(describing: self))
        return hasher.finalize()
    }

    var title: NotificationView.Title? {
        switch self {
        case .error:
            return .string(Localization.commonError)
        case .missingValidRefreshToken:
            return .string(Localization.visaUnlockNotificationTitle)
        case .onboardingAccountActivationInfo:
            return nil
        }
    }

    var description: String? {
        switch self {
        case .error(let error):
            return error.localizedDescription
        case .onboardingAccountActivationInfo:
            return Localization.visaOnboardingApproveWalletSelectorNotificationMessage
        case .missingValidRefreshToken:
            return Localization.visaUnlockNotificationSubtitle
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .missingValidRefreshToken:
            return .primary
        default:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .error:
            return .init(iconType: .image(Assets.redCircleWarning.image))
        case .missingValidRefreshToken:
            return .init(iconType: .image(Assets.lock.image))
        case .onboardingAccountActivationInfo:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        }
    }

    var severity: NotificationView.Severity {
        return .critical
    }

    var isDismissable: Bool {
        return false
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .missingValidRefreshToken(let icon):
            return .init(.unlock(icon: icon), withLoader: true)
        default:
            return nil
        }
    }
}

// MARK: - Analytics

extension VisaNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        false
    }
}
