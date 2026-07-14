//
//  TangemPayComparePlanCell.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets

struct TangemPayComparePlanCell: View {
    let value: String
    let thumbnailURL: String?

    var body: some View {
        Text(value)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)
            .frame(width: Constants.width, height: Constants.height, alignment: .topLeading)
            .overlay(alignment: .topTrailing) { thumbnail }
            .background(DesignSystem.Color.bgTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = thumbnailURL.flatMap({ URL(string: $0) }) {
            KFImage(url)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.thumbnailWidth, height: Constants.thumbnailHeight)
                .padding(16)
        }
    }
}

private extension TangemPayComparePlanCell {
    enum Constants {
        static let width: CGFloat = 332
        static let height: CGFloat = 112
        static let thumbnailWidth: CGFloat = 56
        static let thumbnailHeight: CGFloat = 40
    }
}
