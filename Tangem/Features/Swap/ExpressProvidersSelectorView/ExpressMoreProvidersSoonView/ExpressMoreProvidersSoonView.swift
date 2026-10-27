//
//  ExpressMoreProvidersSoonView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

struct ExpressMoreProvidersSoonView: View {
    var text: String = Localization.expressMoreProvidersSoon

    var body: some View {
        VStack(spacing: 4) {
            Assets.expressMoreProvidersIcon.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconTertiary)

            Text(text)
                .style(Fonts.Regular.footnote, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}
