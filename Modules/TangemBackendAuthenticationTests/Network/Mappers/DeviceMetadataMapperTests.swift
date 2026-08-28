//
//  DeviceMetadataMapperTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct DeviceMetadataMapperTests {
    @Test
    func mapToDTOCopiesEveryFieldVerbatim() {
        let metadata = DeviceMetadata(
            deviceModel: "iPhone 15 Pro",
            os: "iOS",
            osVersion: "17.4.1",
            appVersion: "5.12.0",
            userAgent: "Tangem/5.12.0 (iOS 17.4.1; iPhone 15 Pro)",
            locale: "en-US",
            timezone: "America/New_York"
        )

        let dto = DeviceMetadataMapper.mapToDTO(metadata)

        #expect(dto.deviceModel == metadata.deviceModel)
        #expect(dto.os == metadata.os)
        #expect(dto.osVersion == metadata.osVersion)
        #expect(dto.appVersion == metadata.appVersion)
        #expect(dto.userAgent == metadata.userAgent)
        #expect(dto.locale == metadata.locale)
        #expect(dto.timezone == metadata.timezone)
    }
}
