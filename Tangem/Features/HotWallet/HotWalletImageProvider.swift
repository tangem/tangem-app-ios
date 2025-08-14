//
//  HotWalletImageProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct HotWalletImageProvider {}

// [REDACTED_TODO_COMMENT]
extension HotWalletImageProvider: WalletImageProviding {
    func loadLargeImage() async -> ImageValue {
        ImageValue(image: Image(""))
    }

    func loadSmallImage() async -> ImageValue {
        ImageValue(image: Assets.MobileWallet.mobileWalletInFrame.image)
    }

    func loadLargeUIImage() async -> UIImage {
        UIImage()
    }

    func loadSmallUIImage() async -> UIImage {
        UIImage()
    }
}
