//
//  DeviceMetadata+fake.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@testable import TangemBackendAuthentication

extension DeviceMetadata {
    static let fake = DeviceMetadata(
        deviceModel: "iPhone 15 Pro",
        os: "iOS",
        osVersion: "17.4.1",
        appVersion: "5.12.0",
        userAgent: "Tangem/5.12.0 (iOS 17.4.1; iPhone 15 Pro)",
        locale: "en-US",
        timezone: "America/New_York"
    )
}
