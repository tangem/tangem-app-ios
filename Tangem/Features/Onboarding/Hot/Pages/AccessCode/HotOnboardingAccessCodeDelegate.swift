//
//  HotOnboardingAccessCodeDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotOnboardingAccessCodeDelegate: AnyObject {
    func getUserWalletModel() -> UserWalletModel?
    func didCompleteAccessCode()
}
