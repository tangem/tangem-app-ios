//
//  HotOnboardingAccessCodeCreateDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotOnboardingAccessCodeCreateDelegate: AnyObject {
    func isRequestBiometricsNeeded() -> Bool
    func accessCodeComplete(accessCode: String)
}
