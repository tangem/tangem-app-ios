//
//  KYCWaitingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct KYCWaitingView: View {
    let imageName: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

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

struct KYCWaitingView_Previews: PreviewProvider {
    static var previews: some View {
        KYCWaitingView(imageName: "passport",
                       title: "onboarding_title_pin",
                       subtitle: "onboarding_subtitle_pin")
    }
}
