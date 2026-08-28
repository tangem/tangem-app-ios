//
//  DeviceMetadata+Factory.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemFoundation.DeviceInfo

extension DeviceMetadata {
    static var `default`: DeviceMetadata {
        let deviceInfo = DeviceInfo()

        return DeviceMetadata(
            deviceModel: deviceInfo.device,
            os: "iOS",
            osVersion: deviceInfo.systemVersion,
            appVersion: deviceInfo.version,
            userAgent: "Tangem/\(deviceInfo.version) (iOS \(deviceInfo.systemVersion); \(deviceInfo.device))",
            locale: deviceInfo.language,
            timezone: deviceInfo.timezone
        )
    }
}
