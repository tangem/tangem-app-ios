//
//  MainBottomOverlayView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainBottomOverlayView: View {
    let viewModel: MainBottomOverlayViewModel

    var body: some View {
        MainButton(
            title: viewModel.buttonTitle,
            isDisabled: viewModel.isButtonDisabled,
            action: viewModel.buttonAction
        )
        .padding(.horizontal, 14.0)
        .padding(.top, 14.0)
    }
}
