//
//  PolymarketAvatarView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI

public struct PolymarketAvatarView: View {
    public static let defaultSide: CGFloat = 40

    private let url: URL?
    private let side: CGFloat
    private let isLoading: Bool

    public init(url: URL?, side: CGFloat = PolymarketAvatarView.defaultSide, isLoading: Bool = false) {
        self.url = url
        self.side = side
        self.isLoading = isLoading
    }

    public var body: some View {
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
        static let borderWidth: CGFloat = 1
    }
}
