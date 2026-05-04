//
//  TokenItemPromoProviderOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct SwiftUI.Image

struct TokenItemPromoProviderOutput: Equatable {
    let walletModelId: WalletModelId
    let tokenItem: TokenItem
    let message: String
    let icon: Image
    let appStorageKey: String
}
