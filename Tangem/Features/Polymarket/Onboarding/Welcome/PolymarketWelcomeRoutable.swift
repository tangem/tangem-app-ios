//
//  PolymarketWelcomeRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol PolymarketWelcomeRoutable: AnyObject {
    func onboardingDidFinish(isNewAccount: Bool)
    func openRegionWarning()
    func openLegalTerms(url: URL)
    func dismiss()
}
