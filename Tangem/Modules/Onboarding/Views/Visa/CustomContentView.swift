//
//  CustomContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct CustomContentView: View {
    let imageType: ImageType
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            imageType.image
                .padding(.bottom, 15)

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

struct CustomContentView_Previews: PreviewProvider {
    static var previews: some View {
        CustomContentView(
            imageType: Assets.passport,
            title: Localization.onboardingTitlePin,
            subtitle: Localization.onboardingSubtitlePin
        )
    }
}
