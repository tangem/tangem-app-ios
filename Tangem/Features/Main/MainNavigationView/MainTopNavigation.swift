//
//  MainTopNavigation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI

/// Main is the only screen that needs a decorative logo pinned leading, a balance centred on screen and actions
/// trailing, so it composes the shared `topNavigation` instead of adding a case to it.
///
/// On iOS 26 all three live inside that component's single centred slot and both side bar slots stay empty. This
/// is load-bearing rather than stylistic: a glass leading button on an adjacent screen matches its geometry into
/// whatever occupies this screen's leading slot during push and pop, painting a glass shape over the logo. It was
/// verified on device that nothing applied to a leading item suppresses this — not hiding its shared background,
/// not identity glass, not an identity or materialize glass transition — and that the shape follows the adjacent
/// screen's button rather than ours. An empty slot is the only arrangement with nothing to match into.
///
/// Below iOS 26 nothing morphs, but the same arrangement is used there too rather than a second layout: the
/// actions resolve to their material pill on their own, and one path is easier to reason about than two.
private struct MainTopNavigationModifier<Balance: View>: ViewModifier {
    let scanQRCodeAction: () -> Void
    let detailsAction: () -> Void
    let actionsHaveBackground: Bool
    let balance: Balance

    @State private var barWidth: CGFloat = .zero
    @State private var logoWidth: CGFloat = .zero
    @State private var actionsWidth: CGFloat = .zero
    @State private var balanceWidth: CGFloat = .zero

    func body(content: Content) -> some View {
        content
            .topNavigation(leading: .none) {
                mergedBarContent
            }
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { contentWidth in
                barWidth = max(.zero, contentWidth - Metrics.barHorizontalInset * 2)
            }
    }

    private var mergedBarContent: some View {
        HStack(spacing: .zero) {
            logo

            Spacer(minLength: .zero)

            barActions
        }
        .overlay(alignment: .center) {
            centredBalance
        }
        .frame(width: barWidth)
    }

    private var centredBalance: some View {
        balance
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { balanceWidth = $0 }
            .frame(maxWidth: balanceRegionWidth)
            .offset(x: balanceDrift)
    }

    private var balanceRegionWidth: CGFloat {
        max(.zero, barWidth - logoWidth - actionsWidth - Metrics.balanceGap * 2)
    }

    private var balanceDrift: CGFloat {
        let roomBeforeActions = barWidth / 2 - actionsWidth - Metrics.balanceGap

        return -max(.zero, balanceWidth / 2 - roomBeforeActions)
    }

    private var logo: some View {
        TopNavigationDecoration(image: Assets.tangemIcon, size: Metrics.logoSide)
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { logoWidth = $0 }
    }

    private var barActions: some View {
        TopNavigationActions(actions: actions, hasBackground: actionsHaveBackground)
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { actionsWidth = $0 }
    }

    private var actions: TopNavigation.Actions {
        .two(
            TopNavigation.Action(
                icon: Assets.Glyphs.scanQrIcon,
                accessibilityLabel: Localization.voiceOverOpenNewWalletConnectSession,
                accessibilityIdentifier: MainAccessibilityIdentifiers.scanQrButton,
                action: scanQRCodeAction
            ),
            TopNavigation.Action(
                icon: DesignSystem.Icons.DotsHorizontal.regular24,
                accessibilityLabel: Localization.voiceOverOpenCardDetails,
                accessibilityIdentifier: MainAccessibilityIdentifiers.detailsButton,
                action: detailsAction
            )
        )
    }
}

// MARK: - Metrics

private enum Metrics {
    static let logoSide: CGFloat = .unit(.x8)
    static let barHorizontalInset: CGFloat = 16
    static let balanceGap: CGFloat = 8
}

// MARK: - View extension

extension View {
    func mainTopNavigation(
        scanQRCodeAction: @escaping () -> Void,
        detailsAction: @escaping () -> Void,
        actionsHaveBackground: Bool,
        @ViewBuilder balance: () -> some View
    ) -> some View {
        modifier(
            MainTopNavigationModifier(
                scanQRCodeAction: scanQRCodeAction,
                detailsAction: detailsAction,
                actionsHaveBackground: actionsHaveBackground,
                balance: balance()
            )
        )
    }
}
