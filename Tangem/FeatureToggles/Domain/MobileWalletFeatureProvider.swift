//
//  MobileWalletFeatureProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum MobileWalletFeatureProvider {
    static var isAvailable: Bool {
        guard #available(iOS 16.0, *) else {
            return false
        }
        return FeatureProvider.isAvailable(.mobileWallet)
    }
}
