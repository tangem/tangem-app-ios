//
//  UserWalletListCoordinatorOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletListCoordinatorOutput: AnyObject {
    func dismissAndOpenOnboarding(with input: OnboardingInput)
}
