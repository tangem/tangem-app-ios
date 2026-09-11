//
//  DeviceMetadataMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum DeviceMetadataMapper {
    static func mapToDTO(_ metadata: DeviceMetadata) -> DeviceMetadataDTO.Request {
        DeviceMetadataDTO.Request(
            deviceModel: metadata.deviceModel,
            os: metadata.os,
            osVersion: metadata.osVersion,
            appVersion: metadata.appVersion,
            userAgent: metadata.userAgent,
            locale: metadata.locale,
            timezone: metadata.timezone
        )
    }
}
