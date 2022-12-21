//
//  StoriesBottomButtons.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct StoriesBottomButtons: View {
    let scanColorStyle: MainButton.Style
    let orderColorStyle: MainButton.Style

    let isScanning: Bool

    let scanCard: (() -> Void)
    let orderCard: (() -> Void)

    var body: some View {
        HStack {
            MainButton(
                title: L10n.homeButtonScan,
                style: scanColorStyle,
                isLoading: isScanning,
                action: scanCard
            )

            MainButton(
                title: L10n.homeButtonOrder,
                style: orderColorStyle,
                isDisabled: isScanning,
                action: orderCard
            )
        }
    }
}

struct StoriesBottomButtons_Previews: PreviewProvider {
    static var previews: some View {
        StoriesBottomButtons(scanColorStyle: .primary, orderColorStyle: .secondary, isScanning: false) {

        } orderCard: {

        }
    }
}
