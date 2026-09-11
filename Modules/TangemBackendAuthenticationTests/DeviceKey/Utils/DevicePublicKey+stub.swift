//
//  DevicePublicKey+stub.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
@testable import TangemBackendAuthentication

extension DevicePublicKey {
    static var stub: DevicePublicKey {
        get throws(DevicePublicKey.RawPointFormatError) {
            try DevicePublicKey(
                derRepresentation: Data([0x01, 0x02, 0x03]),
                rawPoint: Data([0x04]) + Data(repeating: 0xAB, count: 64)
            )
        }
    }
}
