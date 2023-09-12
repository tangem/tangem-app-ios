//
//  GenerateAddressesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct GenerateAddressesView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 12) {
                Colors.Icon.accent
                    .frame(size: CGSize(bothDimensions: 36))
                    .clipShape(Circle())
                    .opacity(0.12)
                    .overlay(Assets.blueCircleWarning.image)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Localization.mainWarningMissingDerivationTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                    Text(Localization.mainWarningMissingDerivationDescription(1))
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }

            MainButton(
                title: Localization.commonGenerateAddresses,
                icon: .trailing(Assets.tangemIcon),
                style: .primary
            ) {}
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Colors.Background.action)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }
}

struct GenerateAddressesView_Previews: PreviewProvider {
    static var previews: some View {
        Color.gray
            .overlay(
                GenerateAddressesView()
            )
    }
}
