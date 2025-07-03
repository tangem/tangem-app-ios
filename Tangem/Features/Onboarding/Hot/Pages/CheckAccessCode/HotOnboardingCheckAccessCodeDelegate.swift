//
//  HotOnboardingCheckAccessCodeDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotOnboardingCheckAccessCodeDelegate: AnyObject {
    func checkAccessCode(_ accessCode: String) -> Bool
    func checkSuccessful()
}
