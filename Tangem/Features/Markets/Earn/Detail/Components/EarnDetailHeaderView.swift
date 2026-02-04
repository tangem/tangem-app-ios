//
//  EarnDetailHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct EarnDetailHeaderView: View {
    let headerTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .center, spacing: .zero) {
                Text(headerTitle)
                    .lineLimit(1)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Spacer(minLength: 8)
            }
            .padding(.horizontal, Layout.Content.horizontalPadding)
        }
        .padding(.vertical, Layout.Container.verticalPadding)
        .padding(.horizontal, Layout.Container.horizontalPadding)
    }
}

extension EarnDetailHeaderView {
    enum Layout {
        enum Container {
            static let horizontalPadding: CGFloat = 16.0
            static let verticalPadding: CGFloat = 2.0
        }

        enum Content {
            static let horizontalPadding: CGFloat = 8.0
        }
    }
}
