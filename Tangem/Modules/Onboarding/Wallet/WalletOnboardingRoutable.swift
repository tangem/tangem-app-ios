//
//  WalletOnboardingRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletOnboardingRoutable: OnboardingTopupRoutable {
    func openAccessCodeView(callback: @escaping (String) -> Void)
}
