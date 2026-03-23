//
//  MainHeaderSubtitleView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

enum MainHeaderSubtitleViewState: Hashable {
    case text
    case progress(value: Int)
}

struct MainHeaderSubtitleView: View {
    let subtitleViewState: MainHeaderSubtitleViewState
    let subtitleInfo: MainHeaderSubtitleInfo
    let subtitleContainsSensitiveInfo: Bool
    let isUserWalletLocked: Bool
    let isLoadingSubtitle: Bool
    let subtitleStubWidthScaled: CGFloat
    let subtitleStubHeightScaled: CGFloat

    var body: some View {
        switch subtitleViewState {
        case .text:
            HStack {
                subtitleText
                Spacer()
            }
        case .progress(let value):
            tokenSyncView(progress: value)
        }
    }

    private var subtitleText: some View {
        HStack(spacing: 6) {
            ForEach(subtitleInfo.messages, id: \.self) { message in
                if subtitleContainsSensitiveInfo {
                    SensitiveText(message)
                } else {
                    Text(message)
                }

                if message != subtitleInfo.messages.last {
                    SubtitleSeparator()
                }
            }
        }
        .style(
            subtitleInfo.formattingOption.font,
            color: subtitleInfo.formattingOption.textColor
        )
        .truncationMode(.middle)
        .if(!isUserWalletLocked) {
            $0.skeletonable(
                isShown: isLoadingSubtitle,
                size: CGSize(width: subtitleStubWidthScaled, height: subtitleStubHeightScaled),
                radius: 3
            )
        }
    }

    private func tokenSyncView(progress: Int) -> some View {
        HStack(spacing: 4) {
            SmoothProgressText(progress: progress)
                .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)

            RotatingSyncIcon()

            Spacer()
        }
    }
}

private extension MainHeaderSubtitleView {
    enum Constants {
        static let smoothingTickMs = 100
        static let maxSmoothingStep = 8
        static let progressStepDivisor = 4
    }

    struct SmoothProgressText: View {
        let progress: Int

        @State private var displayedProgress = 0
        @State private var progressSmoothingTask: Task<Void, Never>?

        var body: some View {
            Text(Localization.initialWalletSyncRestoreProgress(displayedProgress))
                .onAppear {
                    startSmoothProgress(to: progress)
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

                while displayedProgress < target, !Task.isCancelled {
                    let delta = target - displayedProgress
                    let step = min(Constants.maxSmoothingStep, max(1, delta / Constants.progressStepDivisor))
                    displayedProgress = min(displayedProgress + step, target)
                    try? await Task.sleep(for: .milliseconds(Constants.smoothingTickMs))

                    guard !Task.isCancelled else {
                        return
                    }
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
                .frame(width: 8, height: 8)
                .foregroundStyle(Colors.Icon.accent)
                .frame(width: 12, height: 12)
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

    struct SubtitleSeparator: View {
        var body: some View {
            Colors.Icon.informative
                .clipShape(Circle())
                .frame(size: .init(bothDimensions: 2.5))
        }
    }
}
