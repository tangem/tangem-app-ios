//
//  NavbarDotsImage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct NavbarDotsImage: View {
    var body: some View {
        Assets.verticalDots.image
            .foregroundColor(DesignSystem.Color.iconPrimary)
    }
}
