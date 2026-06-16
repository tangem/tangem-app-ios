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
    @State private var allModeSectionHeight: CGFloat = .zero

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: Localization.expressProviderForSwap, trailing: {
                NavigationBarButton.close(action: viewModel.dismiss)
            })
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

            if !viewModel.providerTypeFilterOptions.isEmpty {
                TangemSegmentedPicker(
                    data: viewModel.providerTypeFilterOptions,
                    selection: $viewModel.selectedProviderTypeFilter
                )
                .style(.flexible)
                .padding(.top, 4)
                .padding(.bottom, 14)
                .padding(.horizontal, 16)
            }

            ScrollView(.vertical) {
                VStack(spacing: .zero) {
                    if let ukNotificationInput = viewModel.ukNotificationInput {
                        NotificationView(input: ukNotificationInput)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 14)
                    }

                    // [REDACTED_TODO_COMMENT]
                    // [REDACTED_INFO]
                    SelectableSection(viewModel.providerViewModels) { data in
                        SendSwapProvidersSelectorProviderView(data: data, isSelected: viewModel.isSelected(data.id).asBinding)
                    }
                    .enableSeparators(false)
                    .padding(.horizontal, 14)
                    .readGeometry(\.size.height) { height in
                        if viewModel.selectedProviderTypeFilter == .all, height > allModeSectionHeight {
                            allModeSectionHeight = height
                        }
                    }
                    .frame(minHeight: allModeSectionHeight, alignment: .top)

                    ExpressMoreProvidersSoonView()
                        .padding(.top, 18)
                        .padding(.bottom, 16)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
            configuration.sheetFrameUpdateAnimation = .easeInOut
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
        .onDisappear {
            viewModel.selectedProviderTypeFilter = .all
            allModeSectionHeight = .zero
        }
    }
}
