//
//  WelcomeActionSheetView.swift
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

struct WelcomeActionSheetView: View {
    @ObservedObject var viewModel: WelcomeActionSheetViewModel

    var body: some View {
        ZStack {
            if let importViewModel = viewModel.pushedImportSheet {
                WelcomeImportSheetView(viewModel: importViewModel)
                    .transition(.content)
            } else {
                rootContent
                    .transition(.content)
            }
        }
        .floatingSheetConfiguration { config in
            config.backgroundInteractionBehavior = .tapToDismiss
            config.verticalSwipeBehavior = .init(target: .sheet, threshold: Constants.swipeDismissThreshold)
            config.sheetBackground = .color(DesignSystem.Color.bgSecondary)
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

                VStack(spacing: .zero) {
                    ForEach(viewModel.items) { item in
                        row(for: item)
                    }
                }
                .allowsHitTesting(!viewModel.items.contains(where: \.isLoading))
                .padding(.bottom, 20)
            }
        }
    }

    private func row(for item: WelcomeActionSheetItem) -> some View {
        Row(title: item.title, subtitle: item.subtitle)
            .contentLead(.start)
            .start { item.icon.map(RowIcon.init) }
            .end {
                if item.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(DesignSystem.Color.iconSecondary)
                }
            }
            .onTap(action: item.action)
            .accessibilityIdentifier(rowAccessibilityIdentifier(for: item))
    }

    /// Item ids come from `WelcomeCreateWalletActionFactory` and `WelcomeExistingWalletActionFactory`.
    private func rowAccessibilityIdentifier(for item: WelcomeActionSheetItem) -> String? {
        switch item.id {
        case "hardware": WelcomeAccessibilityIdentifiers.actionSheetHardwareRow
        case "mobile": WelcomeAccessibilityIdentifiers.actionSheetMobileRow
        case "import": WelcomeAccessibilityIdentifiers.actionSheetImportRow
        default: nil
        }
    }
}

// MARK: - Row icon

private struct RowIcon: View {
    let icon: ImageType

    @ScaledMetric private var glyphSize = Constants.glyphSize
    @ScaledMetric private var backdropSize = Constants.backdropSize

    var body: some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(size: CGSize(bothDimensions: glyphSize))
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .frame(size: CGSize(bothDimensions: backdropSize))
            .background(DesignSystem.Color.bgTransparentPrimary, in: Circle())
            .accessibilityHidden(true)
    }
}

private extension RowIcon {
    enum Constants {
        static let glyphSize: CGFloat = 20
        static let backdropSize: CGFloat = 40
    }
}

private extension WelcomeActionSheetView {
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
