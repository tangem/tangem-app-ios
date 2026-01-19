//
//  BiometryLogoImage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSdk

enum BiometryLogoImage {
    static var image: Image {
        switch BiometricsUtil.biometryType {
        case .faceID:
            return Assets.Biometry.faceId.image
        case .touchID:
            return Assets.Biometry.touchId.image
        case .opticID:
            return Image(systemName: "opticid")
        case .none:
            return Image("")
        @unknown default:
            return Image("")
        }
    }
}
