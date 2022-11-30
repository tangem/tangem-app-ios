//
//  UserWalletListRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletListRoutable: AnyObject {
    func popToRoot()
    func dismiss()
    func openDisclaimer(at url: URL, _ completion: @escaping (Bool) -> Void)
    func openOnboarding(with input: OnboardingInput)
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
}
