//
//  SendFeeSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SendFeeSelectorView: View {
    @ObservedObject var viewModel: SendFeeSelectorViewModel

    var body: some View {
        VStack(spacing: .zero) {
            header

            FeeSelectorView(viewModel: viewModel.feeSelectorViewModel)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.action
            configuration.sheetFrameUpdateAnimation = .easeInOut
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    var header: some View {
        BottomSheetHeaderView(
            title: Localization.commonNetworkFeeTitle,
            trailing: {
                CircleButton.close(action: viewModel.userDidTapDismissButton)
            }
        )
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
    }
}
