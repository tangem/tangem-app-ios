//
//  CollectiblesSendErrorTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemCollectibles

@Suite("CollectiblesSendError")
struct CollectiblesSendErrorTests {
    @Test("A rejection reports the code of the error inside it, or its own when that one has none", arguments: [
        (CollectiblesSendError.rejected(CollectiblesProgramRejection.paused), 114017005),
        (CollectiblesSendError.rejected(URLError(.timedOut)), 114000001),
    ] as [(CollectiblesSendError, Int)])
    func rejectionCode(error: CollectiblesSendError, expectedCode: Int) {
        #expect(error.errorCode == expectedCode)
    }
}
