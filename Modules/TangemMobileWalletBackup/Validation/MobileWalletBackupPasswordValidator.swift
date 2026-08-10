//
//  MobileWalletBackupPasswordValidator.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Password strength rules for the cloud backup.
public struct MobileWalletBackupPasswordValidator {
    public init() {}

    public func validate(_ password: String) -> Validation {
        let sanitizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        let satisfiedCriteria: Set<Criterion> = Set(Criterion.allCases.filter {
            isSatisfied(password: sanitizedPassword, criterion: $0)
        })

        let satisfiedCount = satisfiedCriteria.count

        let strength: Strength
        if satisfiedCount == Criterion.allCases.count {
            strength = .strong
        } else if satisfiedCriteria.contains(.minimumLength), satisfiedCount >= Constants.minimumCriteriaCountForMediumStrength {
            strength = .medium
        } else {
            strength = .weak
        }

        return Validation(strength: strength, satisfiedCriteria: satisfiedCriteria)
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
        case minimumLength
        case uppercaseLetter
        case lowercaseLetter
        case digit
        case specialCharacter
    }

    enum Strength {
        case weak
        case medium
        case strong
    }

    struct Validation {
        public let strength: Strength
        public let satisfiedCriteria: Set<Criterion>
    }
}

// MARK: - Constants

private extension MobileWalletBackupPasswordValidator {
    enum Constants {
        static let minimumLength = 8
        static let minimumCriteriaCountForMediumStrength = 3
    }
}
