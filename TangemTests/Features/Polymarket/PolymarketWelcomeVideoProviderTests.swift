//
//  PolymarketWelcomeVideoProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
@testable import Tangem

@Suite("Polymarket welcome video")
struct PolymarketWelcomeVideoProviderTests {
    @Test("The welcome video ships in the app bundle")
    func videoIsBundled() throws {
        let url = try #require(PolymarketWelcomeVideoProvider().videoURL())

        #expect(FileManager.default.fileExists(atPath: url.path))
    }
}
