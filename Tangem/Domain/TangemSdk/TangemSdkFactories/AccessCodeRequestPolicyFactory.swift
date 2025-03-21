//
//  AccessCodeRequestPolicyFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AccessCodeRequestPolicyFactory {
    func makePolicy(isAccessCodeSet: Bool) -> AccessCodeRequestPolicy {
        guard isAccessCodeSet else {
            return .default
        }

        if !AppSettings.shared.saveUserWallets {
            return .always
        }

        return AppSettings.shared.saveAccessCodes ? .alwaysWithBiometrics : .always
    }
}
