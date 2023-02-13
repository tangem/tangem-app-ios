//
//  UserWalletListRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletListRoutable: AnyObject {
    func dismiss()
    func openOnboarding(with input: OnboardingInput)
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
}
