//
//  OnboardingTopupViewModelRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol OnboardingTopupViewModelRoutable: AnyObject {
    func openCryptoShop(at url: URL, closeUrl: String, action: @escaping () -> Void)
}
