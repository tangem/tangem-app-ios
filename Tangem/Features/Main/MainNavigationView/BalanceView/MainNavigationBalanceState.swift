//
//  MainNavigationBalanceState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

enum MainNavigationBalanceState: Hashable {
    case loading(text: SensitiveText.TextType? = nil)
    case loaded(text: SensitiveText.TextType)
    case empty
}
