//
//  HotOnboardingAccessCodeCreateRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotOnboardingAccessCodeCreateRoutable: AnyObject {
    /// подумать как переместить в `HotOnboardingAccessCodeCreateView`
    func openAccesCodeSkipAlert(onAllow: @escaping () -> Void)
}
