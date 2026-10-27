//
//  PromoBubbleView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TokenItemPromoBubbleViewModel {
    let id: WalletModelId
    let leadingImage: Image
    let message: String
    let onDismiss: () -> Void
    let onTap: () -> Void
    let onAppear: (() -> Void)?
}
