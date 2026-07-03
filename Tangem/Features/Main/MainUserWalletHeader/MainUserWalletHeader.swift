//
//  MainUserWalletHeader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct MainUserWalletHeader: View {
    @ObservedObject var headerViewModel: MainHeaderViewModel
    let actionButtonsViewModel: ActionButtonsViewModel?
    let showPagingIndicatorStub: Bool

    @ScaledMetric private var scaleFactor: CGFloat = 1
    @ScaledMetric private var height: CGFloat = .unit(.x12)
    @ScaledMetric private var thumbnailSize: CGFloat = 24

    var body: some View {
        VStack(spacing: 0) {
            balance
                .padding(.bottom, Paddings.balanceBottom)

            subtitle
                .padding(.bottom, Paddings.subtitleBottom)

            pagingIndicatorStub

            if let actionButtonsViewModel {
                RedesignActionButtonsView(viewModel: actionButtonsViewModel)
                    .padding(.top, .unit(.x11))
                    .padding(.bottom, .unit(.x6))
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: subtitleAnimationKey)
    }

    @ViewBuilder
    private var balance: some View {
        if headerViewModel.isUserWalletLocked {
            lockedBalance
        } else {
            loadableBalance
        }
    }

    private var lockedBalance: some View {
        Capsule()
            .fill(Color.Tangem.Field.backgroundDefault)
            .frame(size: Sizes.balanceSkeletonSize * scaleFactor)
    }

    private var loadableBalance: some View {
        LoadableBalanceView(
            state: headerViewModel.balance,
            style: .init(
                font: Font.Tangem.Title44.semibold,
                textColor: Color.Tangem.Text.Neutral.primary
            ),
            loader: .init(
                size: Sizes.balanceSkeletonSize * scaleFactor,
                cornerRadiusStyle: .capsule
            ),
            accessibilityIdentifier: MainAccessibilityIdentifiers.totalBalance
        )
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(height: height)
    }

    @ViewBuilder
    private var pagingIndicatorStub: some View {
        if showPagingIndicatorStub {
            Spacer(minLength: .zero)
                .frame(height: Sizes.pagingIndicatorHeight)
        }
    }

    @ViewBuilder
    private var subtitle: some View {
        switch headerViewModel.subtitleViewState {
        case .progress(let value):
            RestoreProgressChip(progress: value)

        case .text:
            walletNameWithThumbnail
        }
    }

    private var walletNameWithThumbnail: some View {
        HStack(spacing: SizeUnit.x1.value) {
            Text(headerViewModel.userWalletName)
                .style(Font.Tangem.Subheadline.medium, color: .Tangem.Text.Neutral.tertiary)

            if let walletThumbnailType = headerViewModel.walletThumbnailType {
                MiniatureWalletView(type: walletThumbnailType)
                    .frame(width: thumbnailSize, height: thumbnailSize)
            }
        }
    }

    private var subtitleAnimationKey: SubtitleAnimationKey {
        switch headerViewModel.subtitleViewState {
        case .text: .text
        case .progress: .progress
        }
    }
}

// MARK: - RestoreProgressChip

private extension MainUserWalletHeader {
    enum ProgressChipConstants {
        static let smoothingTickMs = 100
        static let maxSmoothingStep = 8
        static let progressStepDivisor = 4
        static let iconSize: CGFloat = 24
    }

    struct RestoreProgressChip: View {
        let progress: Int

        var body: some View {
            HStack(spacing: SizeUnit.x1.value) {
                SmoothProgressText(progress: progress)

                RotatingSyncIcon()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    struct SmoothProgressText: View {
        let progress: Int

        @State private var displayedProgress = 0
        @State private var progressSmoothingTask: Task<Void, Never>?

        var body: some View {
            Text(Localization.initialWalletSyncRestoreProgress(displayedProgress))
                .monospacedDigit()
                .style(Font.Tangem.Caption13.regular, color: Color.Tangem.Text.Neutral.tertiary)
                .onAppear {
                    displayedProgress = progress
                }
                .onChange(of: progress) { newValue in
                    startSmoothProgress(to: newValue)
                }
                .onDisappear {
                    cancelSmoothingTask()
                    displayedProgress = 0
                }
        }

        private func startSmoothProgress(to target: Int) {
            guard target != displayedProgress else {
                return
            }

            cancelSmoothingTask()

            progressSmoothingTask = Task { @MainActor in
                if target < displayedProgress {
                    displayedProgress = target
                    return
                }

                while displayedProgress < target {
                    guard !Task.isCancelled else {
                        return
                    }

                    let delta = target - displayedProgress
                    let step = min(
                        ProgressChipConstants.maxSmoothingStep,
                        max(1, delta / ProgressChipConstants.progressStepDivisor)
                    )
                    displayedProgress = min(displayedProgress + step, target)

                    try? await Task.sleep(for: .milliseconds(ProgressChipConstants.smoothingTickMs))
                }
            }
        }

        private func cancelSmoothingTask() {
            progressSmoothingTask?.cancel()
            progressSmoothingTask = nil
        }
    }

    struct RotatingSyncIcon: View {
        @State private var isRotating = false

        var body: some View {
            Assets.Glyphs.load.image
                .resizable()
                .frame(
                    width: ProgressChipConstants.iconSize,
                    height: ProgressChipConstants.iconSize
                )
                .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiary)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .onAppear {
                    isRotating = false
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        isRotating = true
                    }
                }
                .onDisappear {
                    isRotating = false
                }
        }
    }
}

extension MainUserWalletHeader {
    private enum SubtitleAnimationKey {
        case text
        case progress
    }

    enum Paddings {
        static let balanceBottom = CGFloat.unit(.x3)
        static let subtitleBottom = CGFloat.unit(.x2)
    }

    enum Sizes {
        static let pagingIndicatorHeight = CGFloat.unit(.x8)
        static let balanceSkeletonSize = CGSize(width: 222, height: .unit(.x12))
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview {
    @Previewable @State var provider = FakeCardHeaderPreviewProvider()

    VStack(spacing: 20) {
        ForEach(provider.models.indices, id: \.self) { index in
            MainUserWalletHeader(
                headerViewModel: provider.models[index],
                actionButtonsViewModel: nil,
                showPagingIndicatorStub: false
            )
            .onTapGesture {
                let infoProvider = provider.infoProviders[index]
                infoProvider.tapAction(infoProvider)
            }
        }
    }
    .padding()
}
#endif // DEBUG
