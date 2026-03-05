//
//  MobileOnboardingSeedPhraseValidationDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol MobileOnboardingSeedPhraseValidationDelegate: AnyObject {
    func didValidateSeedPhrase()
    func onSeedPhraseValidationBack()
}
