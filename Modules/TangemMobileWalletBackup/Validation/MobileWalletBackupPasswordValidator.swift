//
//  MobileWalletBackupPasswordValidator.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Password strength rules for the cloud backup.
public struct MobileWalletBackupPasswordValidator {
    public init() {}

    public func validate(_ password: String) -> Validation {
        let satisfiedCriteria = makeSatisfiedCriteria(password: password)
        let unsatisfiedCriterion = makeUnsatisfiedCriterion(criteria: satisfiedCriteria)
        let strength = makeStrength(password: password, criteria: satisfiedCriteria)
        let hint = makeHint(password: password, criterion: unsatisfiedCriterion)

        return Validation(strength: strength, hint: hint)
    }

    private func makeSatisfiedCriteria(password: String) -> Set<Criterion> {
        Set(Criterion.allCases.filter {
            isSatisfied(password: password, criterion: $0)
        })
    }

    private func makeStrength(password: String, criteria: Set<Criterion>) -> Strength {
        guard password.isNotEmpty else {
            return .none
        }

        if hasStrongStrength(with: criteria) {
            return .strong
        } else if hasMediumStrength(for: password, with: criteria) {
            return .medium
        } else {
            return .weak
        }
    }

    private func makeHint(password: String, criterion: Criterion?) -> Hint {
        switch password.count {
        case ..<Constants.hintKeepGoingMinimumLength:
            return .tooShort(minimumLength: Constants.minimumLength)
        case ..<Constants.hintCriteriaMinimumLength:
            return .keepGoing(minimumLength: Constants.minimumLength)
        default:
            break
        }

        return switch criterion {
        case .minimumLength: .almostThere
        case .uppercaseLetter: .addUppercaseLetter
        case .lowercaseLetter: .addLowercaseLetter
        case .specialCharacter: .addSpecialCharacter
        case .digit: .addDigit
        case .none: .allSatisfied
        }
    }

    private func hasStrongStrength(with criteria: Set<Criterion>) -> Bool {
        criteria.count == Criterion.allCases.count
    }

    private func hasMediumStrength(for password: String, with criteria: Set<Criterion>) -> Bool {
        guard password.count >= Constants.mediumStrengthMinimumLength else {
            return false
        }
        let satisfiedCriteria = criteria.filter { $0 != .minimumLength }
        return satisfiedCriteria.count >= Constants.mediumStrengthMinimumCriteriaCount
    }

    private func makeUnsatisfiedCriterion(criteria: Set<Criterion>) -> Criterion? {
        Criterion.allCases.first { !criteria.contains($0) }
    }

    private func isSatisfied(password: String, criterion: Criterion) -> Bool {
        switch criterion {
        case .minimumLength: password.count >= Constants.minimumLength
        case .uppercaseLetter: password.contains(#/\p{Lu}/#)
        case .lowercaseLetter: password.contains(#/\p{Ll}/#)
        case .digit: password.contains(#/\p{N}/#)
        case .specialCharacter: password.contains(#/[^\p{L}\p{N}]/#)
        }
    }
}

// MARK: - Nested types

public extension MobileWalletBackupPasswordValidator {
    enum Criterion: CaseIterable {
        case specialCharacter
        case digit
        case uppercaseLetter
        case lowercaseLetter
        case minimumLength
    }

    enum Strength {
        case none
        case weak
        case medium
        case strong
    }

    enum Hint: Equatable {
        case tooShort(minimumLength: Int)
        case keepGoing(minimumLength: Int)
        case almostThere
        case addUppercaseLetter
        case addLowercaseLetter
        case addSpecialCharacter
        case addDigit
        case allSatisfied
    }

    struct Validation {
        public let strength: Strength
        public let hint: Hint
    }
}

// MARK: - Constants

private extension MobileWalletBackupPasswordValidator {
    enum Constants {
        static let minimumLength = 8
        static let mediumStrengthMinimumLength = 6
        static let mediumStrengthMinimumCriteriaCount = 2
        static let hintKeepGoingMinimumLength = 4
        static let hintCriteriaMinimumLength = 7
    }
}
