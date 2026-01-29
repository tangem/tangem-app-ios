//
//  TransactionViewIconView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

struct TransactionViewIconView: View {
    let data: TransactionViewIconViewData
    let size: Size

    var body: some View {
        data.iconBackgroundColor
            .frame(size: .init(bothDimensions: size.size))
            .overlay { iconView }
            .clipShape(Circle())
    }

    @ViewBuilder
    private var iconView: some View {
        switch data.type {
        case .tangemPay(.spend(_, let iconURL, _, _)):
            KFImage(iconURL)
                .resizable()
                .placeholder { assetView }
                .aspectRatio(contentMode: .fit)
                .frame(size: .init(bothDimensions: size.size))
        default:
            assetView
        }
    }

    /// Icon form `TangemAssets`
    @ViewBuilder
    private var assetView: some View {
        data.icon
            .renderingMode(.template)
            .resizable()
            .frame(size: .init(bothDimensions: size.iconSize))
            .foregroundStyle(data.iconColor)
    }
}

extension TransactionViewIconView {
    enum Size {
        case medium
        case large

        var size: CGFloat {
            switch self {
            case .medium: 40
            case .large: 88
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .medium: 20
            case .large: 40
            }
        }
    }
}
