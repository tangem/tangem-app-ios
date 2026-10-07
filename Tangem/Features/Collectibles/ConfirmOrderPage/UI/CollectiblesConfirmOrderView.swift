//
//  CollectiblesConfirmOrderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct CollectiblesConfirmOrderView: View {
    @ObservedObject var viewModel: CollectiblesConfirmOrderViewModel

    let onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var packPose: PackPose = .resting
    @State private var isPackHidden = false
    @State private var isOrderHidden = false
    @State private var isRevealShown = false

    var body: some View {
        ZStack {
            order

            reveal
        }
    }
}

// MARK: - Order

private extension CollectiblesConfirmOrderView {
    var order: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                artwork(in: proxy.size)
                    .infinityFrame()
            }

            orderRows
                .offset(y: orderExitOffset)
                .opacity(isOrderHidden ? 0 : 1)
                .animation(Launch.rowsExit, value: isOrderHidden)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            navigationBar
                .opacity(isRevealShown ? 0 : 1)
                .allowsHitTesting(!isRevealShown)
                .animation(Launch.navigationBarFade, value: isRevealShown)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            approveButton
                .offset(y: orderExitOffset)
                .opacity(isOrderHidden ? 0 : 1)
                .animation(Launch.buttonExit, value: isOrderHidden)
        }
        .task(id: viewModel.buttonState == .packGenerated) {
            guard viewModel.buttonState == .packGenerated else { return }

            await launchPack()
        }
    }
}

// MARK: - Content

private extension CollectiblesConfirmOrderView {
    // MARK: - View properties

    var navigationBar: some View {
        NavigationBar(
            settings: .init(
                backgroundColor: .clear,
                horizontalPadding: Metrics.horizontalPadding,
                height: Metrics.navigationBarHeight
            ),
            titleView: {
                Text(Localization.collectiblesConfirmOrderScreenTitle)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            },
            leftButtons: { NavigationBarButton.back(action: onBack) },
            rightButtons: EmptyView.init
        )
        .padding(.top, Metrics.navigationBarTopPadding)
        .environment(\.isRedesign, true)
    }

    func artwork(in size: CGSize) -> some View {
        let packSize = Self.packSize(in: size)

        return CollectiblesPackCard.Artwork(url: viewModel.artworkURL, packSize: packSize, hasFailureCard: true)
            .frame(width: packSize.width, height: packSize.height)
            .scaleEffect(packPose.scale)
            .rotationEffect(packPose.rotation)
            .offset(packPose.offset)
            .animation(packPose.animation, value: packPose)
            .opacity(isPackHidden ? 0 : 1)
            .animation(Launch.packFade, value: isPackHidden)
    }

    static func packSize(in size: CGSize) -> CGSize {
        let scale = min(1, size.width / Metrics.packSize.width, size.height / Metrics.packSize.height)

        return CGSize(width: Metrics.packSize.width * scale, height: Metrics.packSize.height * scale)
    }

    var orderRows: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.rows, id: \.self) { row in
                Row(title: row.title, value: row.value)
                    .overrideTextColors(.init(title: row.isTotal ? nil : DesignSystem.Color.textSecondary))
                    .showDivider(!row.isTotal)
            }
        }
        .padding(.horizontal, Metrics.rowsHorizontalPadding)
        .padding(.bottom, Metrics.rowsBottomPadding)
    }

    var approveButton: some View {
        TangemUI.Button(label: buttonLabel, accessibilityLabel: nil, action: buttonAction)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .size(.x12)
            .loading(isButtonLoading ? .spinner : nil)
            .disabled(!isButtonEnabled)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.top, Metrics.buttonTopPadding)
            .background(DesignSystem.Color.bgPrimary.ignoresSafeArea(edges: .bottom))
    }

    var buttonLabel: String {
        switch viewModel.buttonState {
        case .notEnoughFunds:
            Localization.collectiblesConfirmOrderNotEnoughFundsButton
        case .balanceUnavailable:
            Localization.commonRetry
        case .generating, .packGenerated:
            // [REDACTED_TODO_COMMENT]
            "Generating pack..."
        case .balanceLoading, .approve:
            Localization.collectiblesConfirmOrderApproveButton
        }
    }

    var isButtonLoading: Bool {
        viewModel.buttonState == .balanceLoading
    }

    @ViewBuilder
    var reveal: some View {
        if isRevealShown, let revealViewModel = viewModel.revealViewModel {
            CollectiblesPackRevealView(viewModel: revealViewModel, onBack: onBack, onKeep: onBack)
                .transition(.opacity.animation(Launch.revealVideoAppearance))
        }
    }

    var isButtonEnabled: Bool {
        viewModel.buttonState == .approve || viewModel.buttonState == .balanceUnavailable
    }

    func buttonAction() {
        guard viewModel.buttonState == .balanceUnavailable else {
            viewModel.approve()
            return
        }

        viewModel.retryBalance()
    }

    var orderExitOffset: CGFloat {
        isOrderHidden && !reduceMotion ? Launch.exitOffset : 0
    }
}

// MARK: - Launch

private extension CollectiblesConfirmOrderView {
    func launchPack() async {
        isOrderHidden = true

        guard !reduceMotion else {
            isPackHidden = true
            isRevealShown = true
            return
        }

        packPose = .dipped

        do {
            try await Task.sleep(for: Launch.dipDuration)
        } catch {
            return
        }

        packPose = .launched
        isPackHidden = true

        do {
            try await Task.sleep(for: Launch.launchDuration)
        } catch {
            return
        }

        isRevealShown = true
    }
}

// MARK: - Metrics

private extension CollectiblesConfirmOrderView {
    enum Metrics {
        static let navigationBarTopPadding: CGFloat = 8
        static let navigationBarHeight: CGFloat = 56
        static let horizontalPadding: CGFloat = 16
        static let packSize = CGSize(width: 302, height: 453)
        static let rowsHorizontalPadding: CGFloat = 8
        static let rowsBottomPadding: CGFloat = 16
        static let buttonTopPadding: CGFloat = 8
    }
}
