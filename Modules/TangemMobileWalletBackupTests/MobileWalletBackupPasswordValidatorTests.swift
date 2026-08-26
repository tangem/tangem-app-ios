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
        "Password with at least 6 characters and at least 2 character classes is medium",
        arguments: [
            "abc12x", // 6 characters, lowercase + digit
            "Abcdex", // 6 characters, uppercase + lowercase
            "Abcdef1", // 7 characters, three character classes, not long enough
            "Abcdefgh", // 8 characters, uppercase + lowercase
        ]
    )
    func mediumPasswords(password: String) {
        #expect(validator.validate(password).strength == .medium)
    }

    @Test(
        "Password shorter than 6 characters or with less than 2 character classes is weak",
        arguments: [
            "abc",
            "aB1!x", // 5 characters, all character classes but too short
            "abcdef", // 6 characters, lowercase only
            "1234567", // 7 characters, digit only
            "abcdefgh", // 8 characters, lowercase only
            "12345678", // 8 characters, digit only
            "!!!!!!!!", // 8 characters, special only
            "        ", // 8 characters, whitespace-only special
        ]
    )
    func weakPasswords(password: String) {
        #expect(validator.validate(password).strength == .weak)
    }

    @Test("Empty password has no strength")
    func emptyPassword() {
        #expect(validator.validate("").strength == MobileWalletBackupPasswordValidator.Strength.none)
    }

    @Test("Whitespace counts as a special character")
    func whitespaceAsSpecialCharacter() {
        #expect(validator.validate("Abcdef 1").strength == .strong)
        #expect(validator.validate("Abcdefg\t1").hint == .allSatisfied)
    }

    // MARK: - Hint

    @Test("Short passwords are hinted by length before criteria")
    func hintLengthThresholds() {
        #expect(validator.validate("").hint == .tooShort(minimumLength: 8))
        #expect(validator.validate("aB1").hint == .tooShort(minimumLength: 8))
        #expect(validator.validate("aB1!").hint == .keepGoing(minimumLength: 8))
        #expect(validator.validate("aB1!aB").hint == .keepGoing(minimumLength: 8))
    }

    @Test("Long enough passwords are hinted by the missing criterion")
    func hintMissingCriterion() {
        #expect(validator.validate("Abcde1!").hint == .almostThere)
        #expect(validator.validate("abcdef1!").hint == .addUppercaseLetter)
        #expect(validator.validate("ABCDEF1!").hint == .addLowercaseLetter)
        #expect(validator.validate("Abcdefg1").hint == .addSpecialCharacter)
        #expect(validator.validate("Abcdefg!").hint == .addDigit)
        #expect(validator.validate("Abcdef1!").hint == .allSatisfied)
    }

    @Test("The highest-priority missing criterion wins")
    func hintPriority() {
        // specialCharacter > digit > uppercaseLetter > lowercaseLetter > minimumLength
        #expect(validator.validate("Abcdefgh").hint == .addSpecialCharacter)
        #expect(validator.validate("abcdefg!").hint == .addDigit)
        #expect(validator.validate("abcdef1!").hint == .addUppercaseLetter)
    }
}
