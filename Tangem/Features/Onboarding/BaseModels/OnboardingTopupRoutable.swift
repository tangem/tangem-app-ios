//
//  OnboardingTopupRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol OnboardingTopupRoutable: OnboardingRoutable, OnboardingBrowserRoutable {
    func openQR(shareAddress: String, address: String, qrNotice: String)
    func openOnramp(walletModel: any WalletModel, userWalletModel: UserWalletModel)
}
