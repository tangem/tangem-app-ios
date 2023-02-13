//
//  BiometryLogoImage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BiometryLogoImage {
    static var image: ImageType {
        switch BiometricAuthorizationUtils.biometryType {
        case .faceID:
            return Assets.Biometry.faceId
        case .touchID:
            return Assets.Biometry.touchId
        case .none:
            return ImageType(name: "")
        @unknown default:
            return ImageType(name: "")
        }
    }
}
