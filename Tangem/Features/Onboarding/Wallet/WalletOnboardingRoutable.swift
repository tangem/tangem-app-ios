//
//  WalletOnboardingRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletOnboardingRoutable: OnboardingRoutable, OnboardingBrowserRoutable {
    func openAccessCodeView(analyticsContextParams: Analytics.ContextParams, callback: @escaping (String) -> Void)
}
