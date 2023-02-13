//
//  EnterPinView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct EnterPinView: View {
    @Binding var text: String

    let title: String
    let subtitle: String

    var maxDigits: Int

    var body: some View {
        VStack(spacing: 10) {
            Spacer()

            Text(title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(subtitle)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)

            PinStackView(maxDigits: maxDigits, pinText: $text)
                .padding(.top, 22)

            Spacer()
        }
    }
}

struct EnterPinView_Previews: PreviewProvider {
    static var previews: some View {
        EnterPinView(text: .constant("0000"), title: Localization.onboardingTitlePin, subtitle: Localization.onboardingSubtitlePin, maxDigits: 4)
    }
}
