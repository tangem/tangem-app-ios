//
//  CardImageProviderMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI
import TangemAssets

struct CardImageProviderMock: CardImageProviding {
    func loadLargeUIImage() async -> UIImage {
        return Assets.Onboarding.walletCard.uiImage
    }

    func loadSmallUIImage() async -> UIImage {
        return Assets.Onboarding.walletCard.uiImage
    }

    func loadLargeImage() async -> ImageValue {
        return ImageValue(image: Image(uiImage: Assets.Onboarding.walletCard.uiImage))
    }

    func loadSmallImage() async -> ImageValue {
        return ImageValue(image: Image(uiImage: Assets.Onboarding.walletCard.uiImage))
    }
}
