//
//  PreserveRule+Testing.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

struct PreserveLogTestCase {
    let originalLog: String
    let preservedLog: String
    let capturedValues: [Substring]
}

func assert(
    preserved testCase: PreserveLogTestCase,
    using sut: PreserveRule,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    var input = testCase.originalLog

    let capturedValues = sut.preserve(&input)
    #expect(input == testCase.preservedLog, sourceLocation: sourceLocation)
    #expect(capturedValues == testCase.capturedValues, sourceLocation: sourceLocation)

    sut.restore(capturedValues, &input)
    #expect(input == testCase.originalLog, sourceLocation: sourceLocation)
}

func assert(ignored testCase: String, using sut: PreserveRule, sourceLocation: SourceLocation = #_sourceLocation) {
    var input = testCase

    let capturedValues = sut.preserve(&input)
    #expect(input == testCase, sourceLocation: sourceLocation)
    #expect(capturedValues == [], sourceLocation: sourceLocation)

    sut.restore(capturedValues, &input)
    #expect(input == testCase, sourceLocation: sourceLocation)
}
