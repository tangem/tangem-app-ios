//
//  CreateWalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct CreateWalletSelectorView: View {
    typealias ViewModel = CreateWalletSelectorViewModel

    @ObservedObject var viewModel: ViewModel

    @State private var scrollToId = UUID()

    var body: some View {
        content
            .allowsHitTesting(!viewModel.isScanning)
            .background(Colors.Background.plain.ignoresSafeArea())
            .onFirstAppear(perform: viewModel.onFirstAppear)
            .alert(item: $viewModel.alert, content: { $0.alert })
            .confirmationDialog(viewModel: $viewModel.confirmationDialog)
            .environment(\.colorScheme, .dark)
    }
}

// MARK: - Content

private extension CreateWalletSelectorView {
    var content: some View {
        VStack(spacing: 0) {
            NavigationBar(
                title: "",
                leftButtons: {
                    BackButton(
                        height: viewModel.backButtonHeight,
                        isVisible: true,
                        isEnabled: true,
                        action: viewModel.onBackTap
                    )
                }
            )

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        info.padding(.horizontal, 20)
                        tangemIcon
                        // actions
                    }
                    .padding(.top, 12)
                    .id(scrollToId)
                }
                .padding(.horizontal, 16)
                .onFirstAppear {
                    proxy.scrollTo(scrollToId, anchor: .bottom)
                }
            }

            // Temporary hide
            primaryActions
                .padding(.horizontal, 16)
        }
    }
}

// MARK: - Subviews

private extension CreateWalletSelectorView {
    var info: some View {
        VStack(spacing: 0) {
            Text(viewModel.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(viewModel.description)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            HorizontalFlowLayout(
                items: viewModel.chipItems,
                alignment: .center,
                horizontalSpacing: 20,
                verticalSpacing: 8,
                itemContent: chip
            )
            .padding(.top, 16)
        }
    }

    var tangemIcon: some View {
        Assets.Onboarding.tangemCardSet.image
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, minHeight: 160)
    }

    var actions: some View {
        VStack(spacing: 0) {
            primaryActions

            actionsSeparator
                .padding(.top, 24)

            secondaryActions
                .padding(.top, 16)
        }
    }

    var primaryActions: some View {
        VStack(spacing: 8) {
            MainButton(
                title: viewModel.scanTitle,
                icon: .trailing(Assets.tangemIcon),
                style: .secondary,
                isLoading: viewModel.isScanning,
                action: viewModel.onScanTap
            )
            .accessibilityIdentifier(StoriesAccessibilityIdentifiers.scanButton)

            MainButton(
                title: viewModel.buyTitle,
                style: .primary,
                action: viewModel.onBuyTap
            )
        }
    }

    var secondaryActions: some View {
        mobileWalletAction(item: viewModel.mobileWalletItem)
    }

    func mobileWalletAction(item: ViewModel.MobileWalletItem) -> some View {
        Button(action: item.action) {
            HStack(spacing: 0) {
                Text(item.title)
                    .style(Fonts.Bold.callout, color: Colors.Text.primary1)

                Assets.chevronRight.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Colors.Icon.primary1)
            }
            .frame(maxWidth: .infinity)
        }
    }

    var actionsSeparator: some View {
        HStack(spacing: 16) {
            HorizontalDots(
                color: Colors.Control.key,
                dotWidth: 4,
                spacing: 2,
                startOpacity: 0,
                endOpacity: 0.4
            )
            .frame(height: 2)

            Text(viewModel.otherMethodTitle)
                .style(Fonts.Bold.caption1, color: Colors.Text.secondary)

            HorizontalDots(
                color: Colors.Control.key,
                dotWidth: 4,
                spacing: 2,
                startOpacity: 0.4,
                endOpacity: 0
            )
            .frame(height: 2)
        }
    }

    func chip(item: ViewModel.ChipItem) -> some View {
        HStack(alignment: .top, spacing: 6) {
            item.icon.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Colors.Icon.accent)
                .frame(width: 16, height: 16)

            Text(item.title)
                .style(Fonts.Bold.footnote, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - HorizontalDots

private struct HorizontalDots: View {
    let color: Color
    let dotWidth: CGFloat
    let spacing: CGFloat
    let startOpacity: Double
    let endOpacity: Double

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: spacing) {
                let dotsCount = dotsCount(in: proxy.size)
                let stepOpacity = (endOpacity - startOpacity) / Double(max(1, dotsCount))

                ForEach(0 ..< dotsCount, id: \.self) { index in
                    Capsule()
                        .fill(color)
                        .opacity(startOpacity + Double(index) * stepOpacity)
                }
            }
        }
    }

    private func dotsCount(in size: CGSize) -> Int {
        Int(size.width / (dotWidth + spacing))
    }
}
