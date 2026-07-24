//
//  EarnSuggestionRowData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

struct EarnSuggestionRowData: Identifiable, Equatable {
    let id: String
    let token: EarnTokenModel
    let tokenIconInfo: TokenIconInfo
    let name: String
    let network: String
    let rateText: String
    let productText: String
}
