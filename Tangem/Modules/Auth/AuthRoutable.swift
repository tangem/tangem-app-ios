//
//  AuthRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol AuthRoutable: AnyObject {
    func openOnboarding(with input: OnboardingInput)
    func openMain(with cardModel: CardViewModel)
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openDisclaimer(at url: URL, _ handler: @escaping (Bool) -> Void)
    func dismiss()
}
