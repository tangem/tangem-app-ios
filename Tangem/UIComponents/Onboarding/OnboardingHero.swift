//
//  OnboardingHero.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct OnboardingHero: View {
    private let media: Media
    private let tint: Tint
    private let scrollSpace: String

    init(image: ImageType, tint: Tint, scrollSpace: String) {
        media = .image(image)
        self.tint = tint
        self.scrollSpace = scrollSpace
    }

    init(video: LoopingVideoBackgroundViewModel, tint: Tint, scrollSpace: String) {
        media = .video(video)
        self.tint = tint
        self.scrollSpace = scrollSpace
    }

    var body: some View {
        Color.clear
            .aspectRatio(Constants.uncoveredAspectRatio, contentMode: .fit)
            .overlay(alignment: .top) {
                GeometryReader { proxy in
                    let overscroll = max(0, proxy.frame(in: .named(scrollSpace)).minY)

                    mediaView
                        .frame(width: proxy.size.width, height: proxy.size.width / Constants.aspectRatio + overscroll)
                        .clipped()
                        .overlay { gradient }
                        .offset(y: -overscroll)
                }
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var mediaView: some View {
        switch media {
        case .image(let image):
            image.image
                .resizable()
                .aspectRatio(contentMode: .fill)
        case .video(let viewModel):
            LoopingVideoBackgroundView(viewModel: viewModel, backgroundColor: DesignSystem.Color.bgPrimary)
        }
    }

    private var gradient: some View {
        LinearGradient(
            stops: [
                .init(color: DesignSystem.Color.bgPrimary.opacity(0), location: tint.start),
                .init(color: DesignSystem.Color.bgPrimary, location: tint.end),
                .init(color: DesignSystem.Color.bgPrimary, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Media

private extension OnboardingHero {
    enum Media {
        case image(ImageType)
        case video(LoopingVideoBackgroundViewModel)
    }
}

// MARK: - Tint

extension OnboardingHero {
    struct Tint {
        let start: CGFloat
        let end: CGFloat
    }
}

extension OnboardingHero.Tint {
    /// The mockup's tint runs from 380 of the image's 608 and is opaque by its bottom edge.
    static let standard = Self(start: 380.0 / 608.0, end: 600.0 / 608.0)
    static let short = Self(start: 448.0 / 608.0, end: 528.0 / 608.0)
}

// MARK: - Constants

private extension OnboardingHero {
    enum Constants {
        /// The mockup's hero image (402×608); its bitmap is placed 405 wide and cropped to the frame.
        static let aspectRatio: CGFloat = 402.0 / 608.0
        /// The mockup starts the content at 495 of the image's 608: the slot ends there and the image overflows it.
        static let uncoveredAspectRatio: CGFloat = 402.0 / 495.0
    }
}
