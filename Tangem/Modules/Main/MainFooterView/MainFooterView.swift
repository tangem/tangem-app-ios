//
//  MainFooterView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainFooterView: View {
    let viewModel: MainFooterViewModel

    let didScrollToBottom: Bool

    @State private var hasBottomSafeAreaInset = false

    private let buttonSize: MainButton.Size = .default

    private var buttonPadding: EdgeInsets {
        // Different padding on devices with/without notch
        let bottomInset = hasBottomSafeAreaInset ? 6.0 : 12.0
        let horizontalInset = 16.0
        return EdgeInsets(top: 14.0, leading: horizontalInset, bottom: bottomInset, trailing: horizontalInset)
    }

    private var overlayViewTopPadding: CGFloat {
        // 75pt is derived from mockups
        return -max(75.0 - buttonPadding.top - buttonSize.height, 0.0)
    }

    var body: some View {
        MainButton(
            title: viewModel.buttonTitle,
            size: buttonSize,
            isDisabled: viewModel.isButtonDisabled,
            action: viewModel.buttonAction
        )
        .padding(buttonPadding)
        .readGeometry(\.safeAreaInsets.bottom) { [oldValue = hasBottomSafeAreaInset] bottomInset in
            let newValue = bottomInset != 0.0
            if newValue != oldValue {
                hasBottomSafeAreaInset = newValue
            }
        }
        .background(
            ListFooterOverlayShadowView()
                .padding(.top, overlayViewTopPadding)
                .hidden(didScrollToBottom)
        )
    }
}
