//
//  StoriesBottomButtons.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct StoriesBottomButtons: View {
    let scanColorStyle: ButtonColorStyle
    let orderColorStyle: ButtonColorStyle
    
    let scanCard: (() -> Void)
    let orderCard: (() -> Void)

    var body: some View {
        HStack {
            Button {
                scanCard()
            } label: {
                Text("home_button_scan")
            }
            .buttonStyle(TangemButtonStyle(colorStyle: scanColorStyle, layout: .flexibleWidth))

            Button {
                orderCard()
            } label: {
                Text("home_button_order")
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(TangemButtonStyle(colorStyle: orderColorStyle, layout: .flexibleWidth))
        }
    }
}

struct StoriesBottomButtons_Previews: PreviewProvider {
    static var previews: some View {
        StoriesBottomButtons(scanColorStyle: .black, orderColorStyle: .grayAlt) {

        } orderCard: {

        }
    }
}
