//
//  UserWalletListOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletListOutput: AnyObject {
    func openOnboarding(with input: OnboardingInput)
}
