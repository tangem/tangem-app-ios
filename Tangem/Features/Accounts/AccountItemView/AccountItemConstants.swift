//
//  AccountItemConstants.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts

enum AccountItemConstants {
    static let collapsedIconSettings = AccountIconView.Settings.defaultSized
    static let expandedIconSettings = AccountIconView.Settings.extraSmallSized

    static var letterConfig: AccountIconView.NameMode.LetterConfig {
        let minimumScaleFactor = expandedIconSettings.size.width / collapsedIconSettings.size.width
        return AccountIconView.NameMode.LetterConfig(minimumScaleFactor: minimumScaleFactor)
    }
}
