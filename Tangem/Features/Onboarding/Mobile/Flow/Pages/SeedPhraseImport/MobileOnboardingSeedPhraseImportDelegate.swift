//
//  MobileOnboardingSeedPhraseImportDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol MobileOnboardingSeedPhraseImportDelegate: AnyObject {
    func didImportSeedPhrase(userWalletModel: UserWalletModel)
    func onSeedPhraseImportBack()
}
