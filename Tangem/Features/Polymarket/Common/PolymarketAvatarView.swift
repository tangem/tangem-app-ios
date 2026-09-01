//
//  PolymarketAvatarView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI

struct PolymarketAvatarView: View {
    let url: URL?
    var side: CGFloat = Constants.defaultSide
    var isLoading: Bool = false

    var body: some View {
        Group {
            if isLoading {
                Shimmer()
            } else if let url {
                KFImage(url)
                    .cancelOnDisappear(true)
                    .placeholder { Shimmer().clipShape(.circle) }
                    .resizable()
                    .scaledToFill()
            } else {
                DesignSystem.Color.bgOpaquePrimary
            }
        }
        .frame(width: side, height: side)
        .clipShape(Circle())
        .overlay { Circle().stroke(DesignSystem.Color.borderPrimary, lineWidth: Constants.borderWidth) }
        .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension PolymarketAvatarView {
    enum Constants {
        static let defaultSide: CGFloat = 40
        static let borderWidth: CGFloat = 1
    }
}
