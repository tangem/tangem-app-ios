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

    var body: some View {
        VStack(spacing: 10) {
            Text("onboarding_title_pin")
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text("onboarding_subtitle_pin")
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)

            TextField("", text: $text)
                .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                .padding(.top, 22)
                .frame(width: 80, height: 58)
                .background(Colors.Field.primary)
        }
    }
}

struct EnterPinView_Previews: PreviewProvider {
    static var previews: some View {
        EnterPinView(text: .constant("0000"))
    }
}
