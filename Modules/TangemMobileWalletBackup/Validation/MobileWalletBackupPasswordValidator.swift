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
        let sanitizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let satisfiedCriteria = makeSatisfiedCriteria(password: sanitizedPassword)
        let unsatisfiedCriterion = makeUnsatisfiedCriterion(satisfiedCriteria: satisfiedCriteria)
        let strength = makeStrength(password: sanitizedPassword, satisfiedCriteria: satisfiedCriteria)

        return Validation(
            strength: strength,
            satisfiedCriteria: satisfiedCriteria,
            unsatisfiedCriterion: unsatisfiedCriterion,
            sanitizedLength: sanitizedPassword.count
        )
    }

    private func makeSatisfiedCriteria(password: String) -> Set<Criterion> {
        Set(Criterion.allCases.filter {
            isSatisfied(password: password, criterion: $0)
        })
    }

    private func makeStrength(password: String, satisfiedCriteria: Set<Criterion>) -> Strength {
        guard password.isNotEmpty else {
            return .none
        }

        if satisfiedCriteria.count == Criterion.allCases.count {
            return .strong
        }

        if
            password.count >= Constants.mediumStrengthMinimumLength,
            satisfiedCriteria.count >= Constants.mediumStrengthMinimumCriteriaCount {
            return .medium
        }

        return .weak
    }

    private func makeUnsatisfiedCriterion(satisfiedCriteria: Set<Criterion>) -> Criterion? {
        Criterion.allCases.first { !satisfiedCriteria.contains($0) }
    }

    private func isSatisfied(password: String, criterion: Criterion) -> Bool {
        switch criterion {
        case .minimumLength: password.count >= Constants.minimumLength
        case .uppercaseLetter: password.contains(#/\p{Lu}/#)
        case .lowercaseLetter: password.contains(#/\p{Ll}/#)
        case .digit: password.contains(#/\p{N}/#)
        case .specialCharacter: password.contains(#/[^\p{L}\p{N}\s]/#)
        }
    }
}

// MARK: - Nested types

public extension MobileWalletBackupPasswordValidator {
    enum Criterion: CaseIterable {
        case digit
        case specialCharacter
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

    struct Validation {
        public let strength: Strength
        public let satisfiedCriteria: Set<Criterion>
        public let unsatisfiedCriterion: Criterion?
        public let sanitizedLength: Int
    }
}

// MARK: - Constants

private extension MobileWalletBackupPasswordValidator {
    enum Constants {
        static let minimumLength = 8
        static let mediumStrengthMinimumLength = 6
        static let mediumStrengthMinimumCriteriaCount = 2
    }
}
