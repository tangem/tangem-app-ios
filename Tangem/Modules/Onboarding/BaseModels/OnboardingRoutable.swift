//
//  OnboardingRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol OnboardingRoutable: AnyObject {
    func onboardingDidFinish()
    func closeOnboarding()
    func openSupportChat(input: SupportChatInputModel)
    func openWebView(with url: URL)
}
