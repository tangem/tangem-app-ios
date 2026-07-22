//
//  OnrampPaymentMethodIconView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct OnrampPaymentMethodIconView: View {
    @Environment(\.colorScheme) private var colorScheme

    let lightURL: URL?
    let darkURL: URL?

    private var usesThemedImages: Bool {
        FeatureProvider.isAvailable(.onrampPaymentMethodThemedImages)
    }

    private var url: URL? {
        guard usesThemedImages else { return lightURL }

        return colorScheme == .dark ? (darkURL ?? lightURL) : (lightURL ?? darkURL)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Colors.Field.focused)
                .frame(size: CGSize(width: 36, height: 36))
                // With themed images off, keep the legacy always-light (white) tile background.
                .environment(\.colorScheme, usesThemedImages ? colorScheme : .light)

            IconView(
                url: url,
                size: CGSize(width: 28, height: 28),
                cornerRadius: 0,
                // Kingfisher shows a grey background even if it has a cached image
                forceKingfisher: false
            )
        }
    }
}
