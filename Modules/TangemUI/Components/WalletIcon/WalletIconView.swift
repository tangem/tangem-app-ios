//
//  WalletIconView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct WalletIconView: View {
    private let content: WalletIconContent?
    private let width: CGFloat

    public init(content: WalletIconContent?, width: CGFloat) {
        self.content = content
        self.width = width
    }

    public var body: some View {
        Group {
            switch content {
            case .image(let image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

            case .none:
                Shimmer()
                    .variant(.custom(width: width, height: (width * 0.61).rounded(), cornerRadius: 3))
            }
        }
        .frame(width: width, height: width)
    }
}
