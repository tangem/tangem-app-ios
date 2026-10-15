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
    @Environment(\.colorScheme) private var colorScheme

    @State private var packPose: PackPose = .resting
    @State private var isPackHidden = false
    @State private var exitProgress: CGFloat = 0
    @State private var isRevealShown = false

    var body: some View {
        ZStack {
            reveal

            order
                .allowsHitTesting(!isRevealShown)
        }
        .overlay(alignment: .top) { errorSnackbar }
        .background(PopGestureDisabler(isDisabled: !isBackAvailable))
        .onAppear { viewModel.preloadRevealAssets(for: colorScheme) }
        .onChange(of: colorScheme, perform: viewModel.preloadRevealAssets)
    }
}

// MARK: - Order

private extension CollectiblesConfirmOrderView {
    var order: some View {
        VStack(spacing: 0) {
            artwork
                .infinityFrame()

            orderRows
                .modifier(LaunchExit(progress: exitProgress, isDelayed: true, shift: exitShift))
        }
        .background(
            DesignSystem.Color.bgPrimary
                .opacity(isRevealShown ? 0 : 1)
                .ignoresSafeArea()
        )
        .safeAreaInset(edge: .top, spacing: 0) {
            navigationBar
                .opacity(isRevealShown ? 0 : 1)
                .allowsHitTesting(!isRevealShown)
                .animation(Launch.navigationBarFade, value: isRevealShown)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            approveButton
                .modifier(LaunchExit(progress: exitProgress, isDelayed: false, shift: exitShift))
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
            leftButtons: {
                if isBackAvailable {
                    NavigationBarButton.back(action: onBack)
                }
            },
            rightButtons: {
                if isBackAvailable {
                    NavigationBarButton.close(action: viewModel.close)
                }
            }
        )
        .padding(.top, Metrics.navigationBarTopPadding)
        .environment(\.isRedesign, true)
    }

    var artwork: some View {
        Color.clear
            .aspectRatio(Metrics.artworkAspectRatio, contentMode: .fit)
            .overlay {
                CollectiblesFractionalFrame(width: Metrics.packWidthFraction, height: 1) {
                    CollectiblesPackCard.Artwork(url: viewModel.artworkURL, hasFailureCard: true, glow: .page)
                        .rotation3DEffect(
                            packPose.rotationX,
                            axis: (x: 1, y: 0, z: 0),
                            perspective: Launch.packPerspective
                        )
                        .rotation3DEffect(
                            packPose.rotationY,
                            axis: (x: 0, y: 1, z: 0),
                            perspective: Launch.packPerspective
                        )
                        .rotationEffect(packPose.rotationZ)
                        .scaleEffect(packPose.scale)
                        .offset(packPose.offset)
                        .animation(packPose.animation, value: packPose)
                        .opacity(isPackHidden ? 0 : 1)
                }
            }
    }

    var orderRows: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.rows) { row in
                Row(title: row.title, value: row.value)
                    .overrideTextColors(.init(title: row.kind == .total ? nil : DesignSystem.Color.textSecondary))
                    .showDivider(row.kind != .total)
            }
        }
        .padding(.horizontal, Metrics.rowsHorizontalPadding)
        .padding(.bottom, Metrics.rowsBottomPadding)
    }

    var approveButton: some View {
        TangemUI.Button(label: buttonLabel, accessibilityLabel: nil, action: buttonAction)
            .styleType(.primary)
            .horizontalLayout(.infinity)
            .size(.x12)
            .loading(isButtonLoading ? .spinner : nil)
            .disabled(!isButtonEnabled)
            .id(buttonLabel)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.top, Metrics.buttonTopPadding)
            .bottomPaddingIfZeroSafeArea()
            .background(DesignSystem.Color.bgPrimary.ignoresSafeArea(edges: .bottom))
    }

    var buttonLabel: String {
        switch viewModel.buttonState {
        case .notEnoughFunds:
            Localization.collectiblesConfirmOrderNotEnoughFundsButton
        case .balanceUnavailable:
            Localization.commonRetry
        // [REDACTED_TODO_COMMENT]
        case .generating:
            "Generating pack..."
        case .confirming:
            "Confirming transaction..."
        case .opening, .packGenerated:
            "Opening pack..."
        case .balanceLoading, .approve:
            Localization.collectiblesConfirmOrderApproveButton
        }
    }

    var isButtonLoading: Bool {
        viewModel.buttonState == .balanceLoading
    }

    @ViewBuilder
    var errorSnackbar: some View {
        if let errorMessage = viewModel.errorMessage {
            TangemSnackbar(title: errorMessage)
                .icon(DesignSystem.Icons.Error.filled20)
                .iconColor(DesignSystem.Color.iconStatusError)
                .padding(.top, Metrics.errorTopPadding)
                .padding(.horizontal, Metrics.horizontalPadding)
                .onTapGesture(perform: viewModel.dismissError)
                .transition(
                    .move(edge: .top)
                        .combined(with: .opacity)
                        .animation(.easeInOut(duration: Metrics.errorAnimationDuration))
                )
        }
    }

    @ViewBuilder
    var reveal: some View {
        if isRevealShown, let revealViewModel = viewModel.revealViewModel {
            CollectiblesPackRevealView(viewModel: revealViewModel, onKeep: onBack)
        }
    }

    var isBackAvailable: Bool {
        guard !isRevealShown else { return false }

        switch viewModel.buttonState {
        case .generating, .confirming, .opening, .packGenerated: return false
        case .balanceLoading, .balanceUnavailable, .approve, .notEnoughFunds: return true
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

    var exitShift: CGFloat {
        reduceMotion ? 0 : Launch.exitOffset
    }
}

// MARK: - Launch

private extension CollectiblesConfirmOrderView {
    func launchPack() async {
        isRevealShown = true

        guard !reduceMotion else {
            exitProgress = 1
            isPackHidden = true
            return
        }

        withAnimation(Launch.exit) { exitProgress = 1 }

        packPose = .dipped

        do {
            try await Task.sleep(for: Launch.dipDuration)
        } catch {
            return
        }

        packPose = .launched

        do {
            try await Task.sleep(for: Launch.launchDuration)
        } catch {
            return
        }

        isPackHidden = true
    }
}

// MARK: - Metrics

private extension CollectiblesConfirmOrderView {
    enum Metrics {
        static let navigationBarTopPadding: CGFloat = 8
        static let navigationBarHeight: CGFloat = 56
        static let horizontalPadding: CGFloat = 16
        static let artworkAspectRatio: CGFloat = 402 / 332
        static let packWidthFraction: CGFloat = 230 / 402
        static let rowsHorizontalPadding: CGFloat = 8
        static let rowsBottomPadding: CGFloat = 16
        static let buttonTopPadding: CGFloat = 8
        static let errorTopPadding: CGFloat = 8
        static let errorAnimationDuration: TimeInterval = 0.25
    }
}
