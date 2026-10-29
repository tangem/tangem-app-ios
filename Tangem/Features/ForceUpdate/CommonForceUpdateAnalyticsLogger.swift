//
//  CommonForceUpdateAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CommonForceUpdateAnalyticsLogger: ForceUpdateAnalyticsLogger {
    func logScreenShown(reason: ForceUpdateReason) {
        Analytics.log(noticeEvent(for: reason))
    }

    func logUpdateNowTapped() {
        Analytics.log(.mainButtonUpdateApp, params: [.source: .critical])
    }

    func logContactSupportTapped(source: ForceUpdateSupportSource) {
        Analytics.log(.requestSupport, params: [.source: source.parameterValue])
    }

    func logLaterTapped() {
        Analytics.log(.mainButtonLater)
    }
}

// MARK: - Private

private extension CommonForceUpdateAnalyticsLogger {
    func noticeEvent(for reason: ForceUpdateReason) -> Analytics.Event {
        switch reason {
        case .requiresAppUpdate:
            return .mainNoticeCriticalUpdate
        case .requiresOSUpdate:
            return .mainNoticeOSUpdate
        case .brick:
            return .mainNoticeUnsupportedDevice
        }
    }
}
