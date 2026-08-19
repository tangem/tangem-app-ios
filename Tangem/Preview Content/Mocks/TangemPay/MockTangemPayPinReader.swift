//
//  MockTangemPayPinReader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct MockTangemPayPinReader: TangemPayPinReader {
    private static let pin = "4821"

    func getPin() async throws -> String {
        if let delayInMilliseconds = ProcessInfo.processInfo.environment["UITEST_TANGEMPAY_PIN_DELAY_MS"].flatMap(UInt64.init) {
            try? await Task.sleep(nanoseconds: delayInMilliseconds * NSEC_PER_MSEC)
        }

        if ProcessInfo.processInfo.environment["UITEST_TANGEMPAY_PIN_ERROR"] == "1" {
            throw MockError.pinUnavailable
        }

        return Self.pin
    }
}

private extension MockTangemPayPinReader {
    enum MockError: Error {
        case pinUnavailable
    }
}
