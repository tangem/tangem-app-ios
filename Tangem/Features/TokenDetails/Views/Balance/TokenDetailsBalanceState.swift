//
//  TokenDetailsBalanceState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

enum TokenDetailsBalanceState {
    typealias Text = SensitiveText.TextType

    case loaded(Text)
    case loadingCached(Text)
    case loading
    case failed(Text)
}
