//
//  DeviceMetadataDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum DeviceMetadataDTO {
    struct Request: Encodable {
        let deviceModel: String
        let os: String
        let osVersion: String
        let appVersion: String
        let userAgent: String
        let locale: String
        let timezone: String
    }
}
