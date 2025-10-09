//
//  CreateWalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct CreateWalletSelectorView: View {
    typealias ViewModel = CreateWalletSelectorViewModel

    @ObservedObject var viewModel: ViewModel

    @State private var introspectResponderChainID = UUID()

    var body: some View {
        content
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .background(Colors.Background.plain.ignoresSafeArea())
            .onAppear(perform: viewModel.onAppear)
            .alert(item: $viewModel.error, content: { $0.alert })
            .actionSheet(item: $viewModel.actionSheet, content: { $0.sheet })
            .sheet(item: $viewModel.mailViewModel) { MailView(viewModel: $0) }
            .environment(\.colorScheme, .dark)
    }
}

// MARK: - Content

private extension CreateWalletSelectorView {
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                info.padding(.horizontal, 20)
                tangemIcon
                actions
            }
        }
        .introspectResponderChain(
            introspectedType: UIScrollView.self,
            includeSubviews: true,
            updateOnChangeOf: introspectResponderChainID,
            action: { scrollView in
                scrollView.alwaysBounceVertical = false
            }
        )
        .introspectResponderChain(
            introspectedType: UINavigationBar.self,
            includeSubviews: true,
            updateOnChangeOf: introspectResponderChainID,
            action: { navigationBar in
                navigationBar.tintColor = UIColor(Colors.Text.constantWhite)
            }
        )
        .onWillAppear {
            DispatchQueue.main.async {
                introspectResponderChainID = UUID()
            }
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

            FlowLayout(
                items: viewModel.chipItems,
                horizontalAlignment: .center,
                verticalAlignment: .center,
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
        VStack(spacing: 24) {
            primaryActions
            actionsSeparator
            secondaryActions
        }
    }

    var primaryActions: some View {
        VStack(spacing: 8) {
            MainButton(
                title: viewModel.scanTitle,
                icon: .trailing(Assets.tangemIcon),
                style: .secondary,
                action: viewModel.onScanTap
            )

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
        VStack(spacing: 0) {
            Text(item.description)
                .style(Fonts.Bold.subheadline, color: Colors.Text.tertiary)

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
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
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
        HStack(spacing: 6) {
            item.icon.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Colors.Icon.accent)
                .frame(width: 16, height: 16)

            Text(item.title)
                .style(Fonts.Bold.footnote, color: Colors.Text.secondary)
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
