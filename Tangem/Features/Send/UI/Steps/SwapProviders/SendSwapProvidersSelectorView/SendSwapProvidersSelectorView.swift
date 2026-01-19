//
//  SendSwapProvidersSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemAssets

struct SendSwapProvidersSelectorView: View {
    @ObservedObject var viewModel: SendSwapProvidersSelectorViewModel

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: Localization.expressChooseProvider, trailing: {
                NavigationBarButton.close(action: viewModel.dismiss)
            })
            .padding(.horizontal, 16)

            if let ukNotificationInput = viewModel.ukNotificationInput {
                NotificationView(input: ukNotificationInput)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }

            SelectableSection(viewModel.providerViewModels) { data in
                SendSwapProvidersSelectorProviderView(data: data, isSelected: viewModel.isSelected(data.id).asBinding)
            }
            // Should start when title starts (14 + 36 + 12)
            .separatorPadding(.init(leading: 62, trailing: 14))
            .padding(.horizontal, 14)

            ExpressMoreProvidersSoonView()
                .padding(.all, 16)
        }
        .padding(.vertical, 4)
        .padding(.bottom, 16)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.primary
            configuration.sheetFrameUpdateAnimation = .easeInOut
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
