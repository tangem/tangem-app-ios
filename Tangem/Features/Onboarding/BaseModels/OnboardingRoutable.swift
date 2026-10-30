//
//  OnboardingRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol OnboardingRoutable: AnyObject {
    func onboardingDidFinish(userWalletModel: UserWalletModel?)
    func closeOnboarding()
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
}

protocol OnboardingBrowserRoutable: AnyObject {
    func openBrowser(at url: URL, onSuccess: @escaping (URL) -> Void)
}
