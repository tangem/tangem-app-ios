//
//  RedactRule+Testing.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

struct RedactLogTestCase {
    let originalLog: String
    let redactedLog: String
}

func assert(
    redacted testCase: RedactLogTestCase,
    using sut: RedactRule,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    var input = testCase.originalLog

    sut.redact(&input)
    #expect(input == testCase.redactedLog, sourceLocation: sourceLocation)
}

func assert(ignored testCase: String, using sut: RedactRule, sourceLocation: SourceLocation = #_sourceLocation) {
    var input = testCase

    sut.redact(&input)
    #expect(input == testCase, sourceLocation: sourceLocation)
}
