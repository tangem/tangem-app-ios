//
//  CircleImageTextView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct CircleImageTextView: View {
    var name: String
    var color: Color

    let size: CGSize

    public var body: some View {
        ZStack {
            Circle()
                .foregroundColor(DesignSystem.Color.bgTransparentSecondary)
            Text(String(name.first ?? " "))
                .font(Font.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(DesignSystem.Color.textInversePrimary)
        }
        .frame(size: size)
        .clipped()
    }
}

#Preview {
    CircleImageTextView(name: "Aave (OLD)", color: .gray, size: CGSize(bothDimensions: 40))
}
