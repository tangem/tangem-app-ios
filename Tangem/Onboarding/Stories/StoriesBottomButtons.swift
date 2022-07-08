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
    
    let isScanning: Bool
    
    let scanCard: (() -> Void)
    let orderCard: (() -> Void)

    var body: some View {
        HStack {
            TangemButton(title: "home_button_scan", action: scanCard)
                .buttonStyle(TangemButtonStyle(colorStyle: scanColorStyle, layout: .flexibleWidth, isLoading: isScanning))

            TangemButton(title: "home_button_order", action: orderCard)
                .buttonStyle(TangemButtonStyle(colorStyle: orderColorStyle, layout: .flexibleWidth))
        }
    }
}

struct StoriesBottomButtons_Previews: PreviewProvider {
    static var previews: some View {
        StoriesBottomButtons(scanColorStyle: .black, orderColorStyle: .grayAlt, isScanning: false) {

        } orderCard: {

        }
    }
}
