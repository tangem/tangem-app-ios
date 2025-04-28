//
//  CustomTokenItemViewInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUI.TokenIconInfo

struct CustomTokenItemViewInfo: Hashable, Identifiable {
    var id: Int { hashValue }

    let tokenItem: TokenItem
    let iconInfo: TokenIconInfo
    let name: String
    let symbol: String
}
