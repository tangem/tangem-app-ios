//
//  BiometricAuthorizationUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import LocalAuthentication
import SwiftUI

enum BiometricAuthorizationUtils {
    static func getBiometricState() -> BiometricState {
        let context = LAContext.default
        var error: NSError?
        let canEvaluatePolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if context.biometryType == .none {
            return .notExist
        }

        if !canEvaluatePolicy {
            return .forbidden
        }

        return .available
    }

    static var biometryType: LABiometryType {
        let context = LAContext.default
        var error: NSError?
        let _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }

    static var allowButtonLocalizationKey: String {
        String(stringLiteral: L10n.saveUserWalletAgreementAllow(biometryType.name))
    }
}

extension LABiometryType {
    var name: String {
        switch self {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return ""
        @unknown default:
            return ""
        }
    }
}

extension BiometricAuthorizationUtils {
    enum BiometricState {
        case notExist
        case forbidden
        case available
    }
}
