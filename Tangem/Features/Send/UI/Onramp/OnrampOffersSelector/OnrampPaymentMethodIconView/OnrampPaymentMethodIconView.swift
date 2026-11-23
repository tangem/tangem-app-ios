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

    private var url: URL? {
        colorScheme == .dark ? (darkURL ?? lightURL) : (lightURL ?? darkURL)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DesignSystem.Color.bgTransparentPrimary)
                .frame(size: CGSize(width: 40, height: 40))

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
