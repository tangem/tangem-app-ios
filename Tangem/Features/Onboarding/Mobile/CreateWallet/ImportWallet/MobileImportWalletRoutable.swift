//
//  MobileImportWalletRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MobileImportWalletRoutable: AnyObject {
    func closeImportWallet()
    func openOnboarding(options: OnboardingCoordinator.Options)
}
