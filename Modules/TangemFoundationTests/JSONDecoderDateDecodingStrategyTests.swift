//
//  JSONDecoderDateDecodingStrategyTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemFoundation

@Suite("JSONDecoder date decoding strategy tests")
struct JSONDecoderDateDecodingStrategyTests {
    @Test
    func customISO8601DecodesDatesWithAndWithoutFractionalSeconds() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601

        let dateWithFractionalSeconds = try decoder.decode(
            DateContainer.self,
            from: Data(#"{"date":"2026-07-30T10:00:00.000Z"}"#.utf8)
        ).date
        let dateWithoutFractionalSeconds = try decoder.decode(
            DateContainer.self,
            from: Data(#"{"date":"2026-07-30T10:00:00Z"}"#.utf8)
        ).date

        #expect(dateWithFractionalSeconds == dateWithoutFractionalSeconds)
    }
}

private extension JSONDecoderDateDecodingStrategyTests {
    struct DateContainer: Decodable {
        let date: Date
    }
}
