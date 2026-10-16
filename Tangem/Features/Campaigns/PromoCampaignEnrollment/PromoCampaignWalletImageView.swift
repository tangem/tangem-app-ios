//
//  PromoCampaignWalletImageView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct PromoCampaignWalletImageView: View {
    let imageProvider: WalletImageProviding
    let side: CGFloat

    @State private var image: ImageValue?

    var body: some View {
        content
            .frame(width: side, height: side)
            .accessibilityHidden(true)
            .task {
                image = await imageProvider.loadSmallImage()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let image {
            image.image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Color.clear
        }
    }
}
