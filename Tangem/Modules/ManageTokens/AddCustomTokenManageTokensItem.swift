//
//  AddCustomTokenManageTokensItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AddCustomTokenManageTokensItemView: View {
    let didTapGenerate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CircleIconView(image: Assets.plusMini.image)
                .padding(.trailing, 12)

            Text(Localization.addCustomTokenTitle)
                .lineLimit(1)
                .layoutPriority(-1)
                .style(Fonts.Bold.subheadline, color: Colors.Text.tertiary)

            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .contentShape(Rectangle())
        .animation(nil) // Disable animations on scroll reuse
        .onTapGesture {
            didTapGenerate()
        }
    }
}

private struct CircleIconView: View {
    let image: Image
    var imageSize: CGSize = .init(width: 16, height: 16)
    var circleSize: CGSize = .init(bothDimensions: 46)

    var body: some View {
        image
            .resizable()
            .frame(width: imageSize.width, height: imageSize.height)
            .background(background)
    }

    @ViewBuilder
    private var background: some View {
        Circle()
            .frame(width: circleSize.width, height: circleSize.height)
            .foregroundColor(Colors.Button.secondary)
    }
}
