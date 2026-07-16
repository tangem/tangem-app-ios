//
//  MainViewRedesignToolbar.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization

public struct MainViewRedesignToolbar<PrincipalContent: View>: ViewModifier {
    private let principalContent: PrincipalContent
    private let trailingButtonsHaveLiquidGlassEffect: Bool
    private let scanQRCodeAction: () -> Void
    private let detailsAction: () -> Void

    public init(
        @ViewBuilder principalContent: () -> PrincipalContent,
        trailingButtonsHaveLiquidGlassEffect: Bool,
        scanQRCodeAction: @escaping () -> Void,
        detailsAction: @escaping () -> Void
    ) {
        self.principalContent = principalContent()
        self.trailingButtonsHaveLiquidGlassEffect = trailingButtonsHaveLiquidGlassEffect
        self.scanQRCodeAction = scanQRCodeAction
        self.detailsAction = detailsAction
    }

    @ScaledMetric private var tangemLogoScaledSide = CGFloat.unit(.x8)
    @State private var navigationBarWidth = CGFloat.zero
    @State private var principalContentWidth = CGFloat.zero

    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            liquidGlassToolbar(content)
        } else {
            regularToolbar(content)
        }
    }

    @available(iOS 26.0, *)
    private func liquidGlassToolbar(_ content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { fullContentWidth in
                navigationBarWidth = max(0, fullContentWidth - NavigationBarInset.horizontal * 2)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: .zero) {
                        tangemLogo

                        Spacer(minLength: .zero)

                        principalContent
                            .onGeometryChange(for: CGFloat.self, of: \.size.width) { principalContentWidth in
                                self.principalContentWidth = principalContentWidth
                            }
                    }
                    // [REDACTED_USERNAME], this is the only proper way to disable liquid glass animation glitch
                    // for leading content while also having some content in the middle.
                    .frame(width: navigationBarWidth / 2 + principalContentWidth / 2)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: .zero) {
                        qrScanButton
                        detailsButton
                    }
                    .glassEffect(
                        trailingButtonsHaveLiquidGlassEffect ? .regular.interactive() : .identity,
                        in: .capsule
                    )
                    .glassEffectTransition(.materialize)
                    .offset(x: 8)
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .animation(.default, value: trailingButtonsHaveLiquidGlassEffect)
            // [REDACTED_USERNAME], this is crucial for leading glass effect removal. ToolbarRole.browser also works
            .toolbarRole(.editor)
    }

    private func regularToolbar(_ content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    tangemLogo
                }

                ToolbarItem(placement: .principal) {
                    principalContent
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: .zero) {
                        qrScanButton
                        detailsButton
                    }
                    .offset(x: 10)
                }
            }
            .backportTranslucentNavigationBar()
    }

    private var tangemLogo: some View {
        Assets.tangemIcon.image
            .renderingMode(.template)
            .resizable()
            .frame(width: tangemLogoScaledSide, height: tangemLogoScaledSide)
            .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)
    }

    private var qrScanButton: some View {
        Button(action: scanQRCodeAction) {
            Assets.Glyphs.scanQrIcon.image
                .renderingMode(.template)
                .resizable()
                .frame(width: .unit(.x7), height: .unit(.x7))
                .foregroundColor(Colors.Icon.primary1)
                .frame(width: .unit(.x11), height: .unit(.x11))
                .padding(.leading, isLiquidGlassSupported ? .unit(.x1) : .zero)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibility(label: Text(Localization.voiceOverOpenNewWalletConnectSession))
        .accessibilityIdentifier(MainAccessibilityIdentifiers.scanQrButton)
    }

    private var detailsButton: some View {
        Button(action: detailsAction) {
            Image(systemName: "ellipsis")
                .frame(width: .unit(.x7), height: .unit(.x7))
                .foregroundColor(Colors.Icon.primary1)
                .frame(width: .unit(.x11), height: .unit(.x11))
                .padding(.trailing, isLiquidGlassSupported ? .unit(.x1) : .zero)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Localization.voiceOverOpenCardDetails)
        .accessibilityIdentifier(MainAccessibilityIdentifiers.detailsButton)
    }
}

private enum NavigationBarInset {
    static let horizontal: CGFloat = 16
}
