//
//  BiometryLogoImage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BiometryLogoImage: View {
    var body: some View {
        switch BiometricAuthorizationUtils.biometryType {
        case .faceID:
            Assets.Biometry.faceId
        case .touchID:
            Assets.Biometry.touchId
        case .none:
            EmptyView()
        @unknown default:
            EmptyView()
        }
    }
}
