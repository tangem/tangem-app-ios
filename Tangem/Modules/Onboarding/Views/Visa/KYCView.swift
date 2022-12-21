//
//  KYCView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct KYCView: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(name: imageName)
                .padding(.bottom, 15)

            Spacer()

            Text(title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(subtitle)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)

            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
    }
}

struct KYCView_Previews: PreviewProvider {
    static var previews: some View {
        KYCView(imageName: "passport",
                title: L10n.onboardingTitlePin,
                subtitle: L10n.onboardingSubtitlePin)
    }
}
