//
//  DeviceMetadataDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct DeviceMetadataDTO: Encodable {
    let deviceModel: String
    let os: String
    let osVersion: String
    let appVersion: String
    let userAgent: String
    let locale: String
    let timezone: String

    static var current: DeviceMetadataDTO {
        let deviceInfo = DeviceInfo()
        let userAgent = "Tangem/\(deviceInfo.version) (iOS \(deviceInfo.systemVersion); \(deviceInfo.device))"

        return DeviceMetadataDTO(
            deviceModel: deviceInfo.device,
            os: deviceInfo.platform,
            osVersion: deviceInfo.systemVersion,
            appVersion: deviceInfo.version,
            userAgent: userAgent,
            locale: deviceInfo.language,
            timezone: deviceInfo.timezone
        )
    }
}
