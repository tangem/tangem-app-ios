//
//  DeviceSignature+fake.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
@testable import TangemBackendAuthentication

extension DeviceSignature {
    static var fake: DeviceSignature {
        get throws(DeviceSignature.RawRepresentationFormatError) {
            try DeviceSignature(
                derRepresentation: Data([0x01, 0x02, 0x03]),
                rawRepresentation: Data(repeating: 0xAB, count: 64)
            )
        }
    }
}
