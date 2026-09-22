//
//  CollectiblesStoriesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemStories
import TangemUI
import TangemUIUtils

struct CollectiblesStoriesView: View {
    @ObservedObject var viewModel: CollectiblesStoriesViewModel

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            tapZones

            slideContent
        }
        .overlay(header, alignment: .top)
        .safeAreaInset(edge: .bottom) { continueButton }
        .environment(\.isRedesign, true)
        .task(viewModel.run)
    }
}

private extension CollectiblesStoriesView {
    // MARK: - View properties

    var header: some View {
        ZStack {
            ProgressBar(
                slidesCount: viewModel.slidesCount,
                currentSlideIndex: viewModel.currentSlideIndex,
                currentSlideProgress: viewModel.currentSlideProgress
            )

            NavigationBarButton.close(action: viewModel.onCloseTap)
                .infinityFrame(axis: .horizontal, alignment: .trailing)
                .padding(.trailing, Metrics.closeTrailingPadding)
        }
        .padding(.top, Metrics.headerTopPadding)
    }

    var tapZones: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                tapZone(onTap: viewModel.onBackwardTap)
                    .frame(width: proxy.size.width * Metrics.backwardTapZoneWidthRatio)

                tapZone(onTap: viewModel.onForwardTap)
            }
        }
    }

    func tapZone(onTap: @escaping () -> Void) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .onLongPressGesture(
                minimumDuration: Metrics.pauseLongPressDuration,
                perform: {},
                onPressingChanged: viewModel.onPressingChanged
            )
    }

    var slideContent: some View {
        VStack(spacing: 8) {
            Text(viewModel.currentSlide.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            Text(viewModel.currentSlide.subtitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Metrics.slideContentHorizontalPadding)
        .padding(.bottom, Metrics.slideContentBottomPadding)
        .infinityFrame(alignment: .bottom)
        .allowsHitTesting(false)
    }

    var continueButton: some View {
        TangemUI.Button(label: viewModel.currentSlide.buttonTitle, accessibilityLabel: nil, action: viewModel.onContinueTap)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .size(.x12)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}

// MARK: - Slide

extension CollectiblesStoriesView {
    struct Slide {
        let title, subtitle, buttonTitle: String

        static let content: [Self] = [
            .init(
                title: Localization.collectiblesStoriesGradedTitle,
                subtitle: Localization.collectiblesStoriesGradedSubtitle,
                buttonTitle: Localization.commonNext
            ),
            .init(
                title: Localization.collectiblesStoriesSecurityTitle,
                subtitle: Localization.collectiblesStoriesSecuritySubtitle,
                buttonTitle: Localization.commonNext
            ),
            .init(
                title: Localization.collectiblesStoriesBuyerTitle,
                subtitle: Localization.collectiblesStoriesBuyerSubtitle,
                buttonTitle: Localization.commonNext
            ),
            .init(
                title: Localization.collectiblesStoriesTransparencyTitle,
                subtitle: Localization.collectiblesStoriesTransparencySubtitle,
                buttonTitle: Localization.commonNext
            ),
            .init(
                title: Localization.collectiblesStoriesOwnershipTitle,
                subtitle: Localization.collectiblesStoriesOwnershipSubtitle,
                buttonTitle: Localization.collectiblesStoriesBrowsePacksButton
            ),
        ]
    }
}

// MARK: - Metrics

private extension CollectiblesStoriesView {
    enum Metrics {
        static let headerTopPadding: CGFloat = 8
        static let closeTrailingPadding: CGFloat = 16

        static let backwardTapZoneWidthRatio: CGFloat = 1.0 / 3.0
        static let pauseLongPressDuration: TimeInterval = 0.25

        static let slideContentHorizontalPadding: CGFloat = 24
        /// Text-to-button gap per the mockup: 48 here plus the button's own 8pt top inset.
        static let slideContentBottomPadding: CGFloat = 48
    }
}

// MARK: - Previews

#Preview {
    CollectiblesStoriesView(
        viewModel: CollectiblesStoriesViewModel(
            slides: CollectiblesStoriesView.Slide.content,
            engine: {
                StoryPlayerViewModel(
                    story: $0,
                    source: .collectibles,
                    hapticPlayer: CommonStoryHapticPlayer(),
                    onFinished: { _, _ in }
                )
            }
        )
    )
}
