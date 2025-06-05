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
    var body: some View {
        VStack(spacing: 4) {
            Assets.expressMoreProvidersIcon.image
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.inactive)

            Text(Localization.expressMoreProvidersSoon)
                .style(Fonts.Regular.footnote, color: Colors.Icon.informative)
                .multilineTextAlignment(.center)
        }
    }
}
