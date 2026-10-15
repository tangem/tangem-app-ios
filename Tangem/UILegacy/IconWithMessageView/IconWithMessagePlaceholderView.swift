//
//  IconWithMessagePlaceholderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct IconWithMessagePlaceholderView: View {
    private let icon: ImageType

    init(icon: ImageType) {
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 14) {
            IconWithBackground(icon: icon)

            VStack(alignment: .leading) {
                Shimmer()
                    .variant(.custom(width: 40, height: 11, cornerRadius: 3))

                Shimmer()
                    .variant(.custom(width: 102, height: 21, cornerRadius: 6))
            }

            Spacer()
        }
    }
}

#Preview {
    IconWithMessagePlaceholderView(icon: Assets.cryptoCurrencies)
}
