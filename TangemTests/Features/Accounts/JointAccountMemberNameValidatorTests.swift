//
//  JointAccountMemberNameValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

@Suite("Tests for the rules the name of a joint account member is checked against")
struct JointAccountMemberNameValidatorTests {
    private let validator = JointAccountMemberNameValidator()

    @Test(
        "A real name is accepted whatever punctuation and diacritics it carries",
        arguments: [
            "Anne-Marie",
            "O'Brien",
            "José",
            "Ægir",
            "Łukasz",
            "Nguyễn",
            "Müller-Schmidt",
            "Jean-Luc O'Néill",
            "Alice 🙂",
            "Member 2",
        ]
    )
    func nameWithPunctuationOrDiacriticsIsAccepted(name: String) throws {
        try validator.validate(name)
    }

    @Test("A name of nothing but whitespace is no name", arguments: ["", " ", "   ", "\n", "\t"])
    func blankNameIsRejected(name: String) {
        #expect(throws: JointAccountMemberNameValidator.ValidationError.empty) {
            try validator.validate(name)
        }
    }

    @Test("A name is accepted right up to the length limit")
    func nameAtTheLengthLimitIsAccepted() throws {
        let name = String(repeating: "a", count: JointAccountMemberNameValidator.maxLength)

        try validator.validate(name)
    }

    @Test("A name one character past the limit is rejected")
    func nameOverTheLengthLimitIsRejected() {
        let name = String(repeating: "a", count: JointAccountMemberNameValidator.maxLength + 1)

        #expect(throws: JointAccountMemberNameValidator.ValidationError.tooLong) {
            try validator.validate(name)
        }
    }
}
