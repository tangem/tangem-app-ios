//
//  MobileWalletBackupPasswordValidatorTests.swift
//  TangemMobileWalletBackupTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemMobileWalletBackup

@Suite("MobileWalletBackupPasswordValidator")
struct MobileWalletBackupPasswordValidatorTests {
    private let validator = MobileWalletBackupPasswordValidator()

    // MARK: - Strength

    @Test(
        "Password satisfying all criteria is strong",
        arguments: ["Abcdef1!", "Str0ng#Password", "aB1!aB1!"]
    )
    func strongPasswords(password: String) {
        #expect(validator.validate(password).strength == .strong)
    }

    @Test(
        "Password with at least 6 characters and at least 2 criteria is medium",
        arguments: [
            "abc12x", // 6 characters, lowercase + digit
            "Abcdex", // 6 characters, uppercase + lowercase
            "Abcdef1", // 7 characters, three criteria, not long enough
            "abcdefgh", // 8 characters, minimum length + lowercase
            "12345678", // 8 characters, minimum length + digit
        ]
    )
    func mediumPasswords(password: String) {
        #expect(validator.validate(password).strength == .medium)
    }

    @Test(
        "Password shorter than 6 characters or with less than 2 criteria is weak",
        arguments: [
            "abc",
            "aB1!x", // 5 characters, all character criteria but too short
            "abcdef", // 6 characters, lowercase only
            "1234567", // 7 characters, digit only
        ]
    )
    func weakPasswords(password: String) {
        #expect(validator.validate(password).strength == .weak)
    }

    @Test(
        "Empty password has no strength",
        arguments: ["", "   "]
    )
    func emptyPasswords(password: String) {
        #expect(validator.validate(password).strength == MobileWalletBackupPasswordValidator.Strength.none)
    }

    @Test("Surrounding whitespace is ignored")
    func whitespaceTrimming() {
        #expect(validator.validate("  abc  ").strength == validator.validate("abc").strength)
        #expect(validator.validate(" Abcdef1! ").strength == .strong)
    }

    // MARK: - Criteria

    @Test("Missing criteria are reported")
    func satisfiedCriteria() {
        #expect(validator.validate("Abcdef1!").satisfiedCriteria == Set(MobileWalletBackupPasswordValidator.Criterion.allCases))
        #expect(validator.validate("Abcdefg1").satisfiedCriteria == [.minimumLength, .uppercaseLetter, .lowercaseLetter, .digit])
        #expect(validator.validate("Abcde1!").satisfiedCriteria == [.uppercaseLetter, .lowercaseLetter, .digit, .specialCharacter])
        #expect(validator.validate("").satisfiedCriteria.isEmpty)
    }

    // MARK: - Unsatisfied criterion

    @Test("No criterion is unsatisfied when all criteria are satisfied")
    func unsatisfiedCriterionAllSatisfied() {
        #expect(validator.validate("Abcdef1!").unsatisfiedCriterion == nil)
    }

    @Test("The single missing criterion is reported as unsatisfied")
    func unsatisfiedCriterionSingleMissing() {
        #expect(validator.validate("Abcdefg1").unsatisfiedCriterion == .specialCharacter)
        #expect(validator.validate("Abcdefg!").unsatisfiedCriterion == .digit)
        #expect(validator.validate("abcdef1!").unsatisfiedCriterion == .uppercaseLetter)
        #expect(validator.validate("ABCDEF1!").unsatisfiedCriterion == .lowercaseLetter)
        #expect(validator.validate("Abcde1!").unsatisfiedCriterion == .minimumLength)
    }

    @Test("The highest-priority missing criterion wins")
    func unsatisfiedCriterionPriority() {
        // digit > specialCharacter > uppercaseLetter > lowercaseLetter > minimumLength
        #expect(validator.validate("Abcdefgh").unsatisfiedCriterion == .digit)
        #expect(validator.validate("abcdefg1").unsatisfiedCriterion == .specialCharacter)
        #expect(validator.validate("abcdef1!").unsatisfiedCriterion == .uppercaseLetter)
        #expect(validator.validate("").unsatisfiedCriterion == .digit)
    }
}
