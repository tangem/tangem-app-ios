//
//  ReferralPlaceholderPointView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReferralPlaceholderPointView: View {
    private let icon: Image

    init(icon: Image) {
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 14) {
            ReferralPointIcon(icon: icon)

            VStack(alignment: .leading) {
                Color.white
                    .skeletonable(isShown: true, size: .init(width: 102, height: 21), radius: 6)

                Color.white
                    .skeletonable(isShown: true, size: .init(width: 40, height: 11), radius: 3)
            }

            Spacer()
        }
    }
}

struct ReferralLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        ReferralPlaceholderPointView(icon: Assets.cryptocurrencies)
    }
}
