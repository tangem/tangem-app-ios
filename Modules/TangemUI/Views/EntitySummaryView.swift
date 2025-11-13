//
//  ModalViewDescriptionHeader.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import Kingfisher
import TangemFoundation
import TangemAccessibilityIdentifiers

public struct EntitySummaryView: View {
    private let viewState: ViewState
    private let kingfisherImageCache: ImageCache

    public init(viewState: ViewState, kingfisherImageCache: ImageCache) {
        self.viewState = viewState
        self.kingfisherImageCache = kingfisherImageCache
    }

    public var body: some View {
        HStack(spacing: 16) {
            iconView

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 4) {
                    titleView
                    titleInfoView
                    Spacer(minLength: .zero)
                }

                subtitleView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.linear(duration: 0.2), value: viewState)
    }

    // MARK: - Icon

    private var iconView: some View {
        ZStack {
            switch viewState {
            case .loading:
                SkeletonView()
                    .frame(width: 56, height: 56)
                    .transition(.opacity)
            case .content(let contentState):
                makeIcon(from: contentState.imageLocation)
            }
        }
        .if(shouldClipIcon) { view in
            view.clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var shouldClipIcon: Bool {
        guard case .content(let contentState) = viewState else {
            return true
        }

        // Don't clip custom views - they manage their own clipping
        if case .customView = contentState.imageLocation {
            return false
        }

        return true
    }

    @ViewBuilder
    private func makeIcon(from imageLocation: ViewState.ContentState.ImageLocation) -> some View {
        switch imageLocation {
        case .bundle(let imageType):
            imageType.image
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(Colors.Icon.accent)
                .frame(width: 56, height: 56)
                .background(Colors.Icon.accent.opacity(0.1))

        case .customView(let customViewWrapper):
            customViewWrapper.view
                .transition(.opacity)

        case .remote(let remoteIconConfig) where remoteIconConfig.iconURL == nil:
            fallbackIconAsset
                .transition(.opacity)

        case .remote(let remoteIconConfig):
            remoteIcon(remoteIconConfig)
                .transition(.opacity)
        }
    }

    private func remoteIcon(_ remoteIconConfig: ViewState.ContentState.ImageLocation.RemoteImageConfig) -> some View {
        KFImage(remoteIconConfig.iconURL)
            .targetCache(kingfisherImageCache)
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(width: 56, height: 56)
    }

    private var fallbackIconAsset: some View {
        Assets.Glyphs.explore.image
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .foregroundStyle(Colors.Icon.accent)
            .frame(width: 56, height: 56)
            .background(Colors.Icon.accent.opacity(0.1))
    }

    // MARK: - Title

    @ViewBuilder
    private var titleView: some View {
        switch viewState {
        case .content(let contentState):
            Text(contentState.title)
                .lineLimit(2)
                .style(Fonts.Bold.title3.weight(.semibold), color: Colors.Text.primary1)
                .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.entityProviderName)
                .transition(.opacity)

        case .loading:
            SkeletonView()
                .frame(width: 120, height: 26)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var titleInfoView: some View {
        if case .content(let contentState) = viewState,
           let titleInfoConfig = contentState.titleInfoConfig {
            Button(action: titleInfoConfig.onTap) {
                titleInfoConfig.imageType.image
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(titleInfoConfig.foregroundColor)
                    .contentShape(.circle)
                    .padding(.top, 2)
            }
            .buttonStyle(.plain)
            .transition(.opacity)
        }
    }

    // MARK: - Subtitle

    @ViewBuilder
    private var subtitleView: some View {
        switch viewState {
        case .content(let contentState):
            Text(contentState.subtitle)
                .lineLimit(1)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .transition(.opacity)

        case .loading:
            SkeletonView()
                .frame(width: 168, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.opacity)
        }
    }
}

public extension EntitySummaryView {
    enum ViewState: Equatable {
        case loading
        case content(ContentState)

        public var isLoading: Bool {
            switch self {
            case .loading: true
            case .content: false
            }
        }
    }
}

public extension EntitySummaryView.ViewState {
    struct ContentState: Equatable {
        public let imageLocation: ImageLocation
        public let title: String
        public let subtitle: String
        public let titleInfoConfig: TitleInfoConfig?

        public init(imageLocation: ImageLocation, title: String, subtitle: String, titleInfoConfig: TitleInfoConfig?) {
            self.imageLocation = imageLocation
            self.title = title
            self.subtitle = subtitle
            self.titleInfoConfig = titleInfoConfig
        }
    }
}

public extension EntitySummaryView.ViewState {
    struct TitleInfoConfig: Equatable {
        let imageType: ImageType
        let foregroundColor: Color
        @IgnoredEquatable var onTap: () -> Void

        public init(imageType: ImageType, foregroundColor: Color, onTap: @escaping () -> Void) {
            self.imageType = imageType
            self.foregroundColor = foregroundColor
            self.onTap = onTap
        }
    }
}

public extension EntitySummaryView.ViewState.ContentState {
    enum ImageLocation: Equatable {
        case bundle(ImageType)
        case customView(CustomViewWrapper)
        case remote(RemoteImageConfig)
    }
}

public extension EntitySummaryView.ViewState.ContentState.ImageLocation {
    struct CustomViewWrapper: Equatable {
        @IgnoredEquatable var view: AnyView

        public init<Content: View>(@ViewBuilder content: () -> Content) {
            view = AnyView(content())
        }

        public static func == (lhs: CustomViewWrapper, rhs: CustomViewWrapper) -> Bool {
            true
        }
    }
}

public extension EntitySummaryView.ViewState.ContentState.ImageLocation {
    struct RemoteImageConfig: Equatable {
        let iconURL: URL?
        let fallbackIconAsset = Assets.Glyphs.explore

        public init(iconURL: URL?) {
            self.iconURL = iconURL
        }
    }
}
