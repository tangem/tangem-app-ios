//
//  CustomerIOSharedConfiguration.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CioInternalCommon
import CioMessagingPush

// The Data Pipeline SDK is app-only; the extension must not link it (NSE memory limit).
#if !IS_APP_EXTENSION
import CioDataPipelines
#endif

/// Customer.io configuration shared between the app and the Notification Service Extension. Member of
/// both targets so the values can't drift — a region mismatch would point them at different workspaces
/// and the `delivered` metric would never reconcile.
enum CustomerIOSharedConfiguration {
    /// Region of the Tangem Customer.io workspace, not the user's location.
    static let region: Region = .EU

    static let logLevel: CioLogLevel = .error
}

// MARK: - SDKConfigBuilder + Tangem

#if !IS_APP_EXTENSION
extension SDKConfigBuilder {
    /// Data Pipeline SDK defaults — app-only (the extension doesn't link `CioDataPipelines`).
    func tangemDataPipelineDefaults() -> SDKConfigBuilder {
        let builder = self
        return builder
            .region(CustomerIOSharedConfiguration.region)
            .logLevel(CustomerIOSharedConfiguration.logLevel)
            .autoTrackUIKitScreenViews(enabled: false)
            .autoTrackDeviceAttributes(false)
            .trackApplicationLifecycleEvents(false)
    }
}
#endif

// MARK: - Shared push configuration

extension MessagingPushConfigBuilder {
    /// Push parameters shared by both targets. `region`/`logLevel` aren't set here — the app applies them
    /// via the Data Pipeline SDK, the extension directly on this builder. `autoFetchDeviceToken(false)`:
    /// Tangem registers the token itself; `autoTrackPushEvents(true)`: emit the `delivered`/`opened` metrics.
    func tangemPushDefaults() -> MessagingPushConfigBuilder {
        let builder = self
        return builder
            .autoFetchDeviceToken(false)
            .autoTrackPushEvents(true)
    }
}
