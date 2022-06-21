//
//  OnboardingTopupRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol OnboardingTopupRoutable: OnboardingRoutable {
    func openCryptoShop(at url: URL, closeUrl: String, action: @escaping (String) -> Void)
    func openQR(shareAddress: String, address: String, qrNotice: String)
}
