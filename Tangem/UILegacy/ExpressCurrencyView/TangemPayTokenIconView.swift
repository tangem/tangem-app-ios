//
//  TangemPayTokenIconView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPayTokenIconView: View {
    let size: CGSize

    var body: some View {
        Assets.Visa.tokenAvatar.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(size: size)
    }
}

// MARK: - Previews

#Preview {
    TangemPayTokenIconView(size: CGSize(width: 36, height: 36))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
}
