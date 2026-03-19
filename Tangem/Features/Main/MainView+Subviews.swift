//
//  MainView+Subviews.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemFoundation
import TangemUI
import TangemLocalization
import TangemAccessibilityIdentifiers

extension MainView {
    // MARK: - RedesignedNavigationModifier

    struct RedesignedNavigationModifier: ViewModifier {
        @State private var opacity: CGFloat = 0

        let openDetailsAction: () -> Void
        let openQRScanAction: () -> Void
        let headerHeightRatioPublisher: AnyPublisher<CGFloat, Never>
        let pageBuilder: MainUserWalletPageBuilder

        func body(content: Content) -> some View {
            content
                .navigationToolbar(
                    leadingContent: leadingContent,
                    principalContent: principalContent,
                    trailingContent: trailingContent
                )
                .onReceive(headerHeightRatioPublisher) { ratio in
                    // Increases linearly from 0 to 1 value as height collapses from 60% to 40%
                    opacity = clamp(3 - 5 * ratio, min: 0, max: 1)
                }
        }

        private func leadingContent() -> some View {
            TangemNavigationHeader.LeadingIcon()
        }

        private func principalContent() -> some View {
            pageBuilder.navigation
                .opacity(opacity)
                .animation(.default, value: opacity)
        }

        private func trailingContent() -> some View {
            TangemNavigationHeader.TrailingButtons(
                secondaryAction: qrScanAction,
                action: detailsAction
            )
        }

        private var detailsAction: TangemNavigationHeader.ActionInfo {
            TangemNavigationHeader.ActionInfo(
                action: openDetailsAction,
                accessibilityIdentifier: MainAccessibilityIdentifiers.detailsButton,
                accessibilityLabel: Localization.voiceOverOpenCardDetails
            )
        }

        private var qrScanAction: TangemNavigationHeader.ActionInfo? {
            FeatureProvider.isAvailable(.mainQRScan)
                ? TangemNavigationHeader.ActionInfo(
                    action: openQRScanAction,
                    accessibilityIdentifier: MainAccessibilityIdentifiers.scanQrButton,
                    accessibilityLabel: Localization.voiceOverOpenNewWalletConnectSession
                )
                : nil
        }
    }

    // MARK: - RedesignedBackgroundModifier

    struct RedesignedBackgroundModifier: ViewModifier {
        @State private var opacity: CGFloat = 1

        let headerHeightRatioPublisher: AnyPublisher<CGFloat, Never>

        func body(content: Content) -> some View {
            content
                .northernLightsBackground(
                    backgroundColor: .Tangem.Surface.level2,
                    opacity: opacity
                )
                .onReceive(headerHeightRatioPublisher) { ratio in
                    // Decreases linearly from 1 to 0 value as height collapses from 100% to 50%
                    opacity = clamp(2 * ratio - 1, min: 0, max: 1)
                }
        }
    }
}
