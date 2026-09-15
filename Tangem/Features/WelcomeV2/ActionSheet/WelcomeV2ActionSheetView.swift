//
//  WelcomeV2ActionSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct WelcomeV2ActionSheetView: View {
    @ObservedObject var viewModel: WelcomeV2ActionSheetViewModel

    var body: some View {
        ZStack {
            if let importViewModel = viewModel.pushedImportSheet {
                WelcomeV2ImportSheetView(viewModel: importViewModel)
                    .transition(.content)
            } else {
                rootContent
                    .transition(.content)
            }
        }
        .floatingSheetConfiguration { config in
            config.backgroundInteractionBehavior = .tapToDismiss
            config.verticalSwipeBehavior = .init(target: .sheet, threshold: Constants.swipeDismissThreshold)
            config.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            config.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }

    private var rootContent: some View {
        FloatingSheetContentWithHeader(
            headerConfig: .init(
                title: viewModel.title,
                backAction: viewModel.onBack,
                closeAction: viewModel.onClose
            )
        ) {
            VStack(spacing: 12) {
                if let subtitle = viewModel.subtitle {
                    Text(subtitle)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }

                VStack(spacing: 8) {
                    ForEach(viewModel.items) { item in
                        row(for: item)
                    }
                }
                .allowsHitTesting(!viewModel.items.contains(where: \.isLoading))
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }

    private func row(for item: WelcomeV2ActionSheetItem) -> some View {
        Row(title: item.title, subtitle: item.subtitle)
            .contentLead(.start)
            .start(icon: item.icon)
            .end {
                if item.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(DesignSystem.Color.iconSecondary)
                } else {
                    DesignSystem.Icons.ChevronRight.regular16.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconSecondary)
                }
            }
            .onTap(item.action)
            .background(DesignSystem.Color.bgOpaquePrimary)
            .cornerRadiusContinuous(14)
            .accessibilityIdentifier(rowAccessibilityIdentifier(for: item))
    }

    /// Item ids come from `WelcomeV2CreateWalletActionFactory` and `WelcomeV2ExistingWalletActionFactory`.
    private func rowAccessibilityIdentifier(for item: WelcomeV2ActionSheetItem) -> String? {
        switch item.id {
        case "hardware": WelcomeV2AccessibilityIdentifiers.actionSheetHardwareRow
        case "mobile": WelcomeV2AccessibilityIdentifiers.actionSheetMobileRow
        case "import": WelcomeV2AccessibilityIdentifiers.actionSheetImportRow
        default: nil
        }
    }
}

private extension WelcomeV2ActionSheetView {
    enum Constants {
        static let swipeDismissThreshold: CGFloat = 100
    }
}

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )
}
