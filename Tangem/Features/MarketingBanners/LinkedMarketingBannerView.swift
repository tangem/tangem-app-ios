//
//  LinkedMarketingBannerView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemFoundation

struct LinkedMarketingBannerViewModel: Hashable {
    let id: Int
    let text: String
    let iconURL: URL?

    @IgnoredEquatable
    var action: (() -> Void)?

    init(id: Int, text: String, iconURL: URL?, action: (() -> Void)? = nil) {
        self.id = id
        self.text = text
        self.iconURL = iconURL
        self.action = action
    }
}

struct LinkedMarketingBannerView: View {
    let viewModel: LinkedMarketingBannerViewModel

    private static let topOverlap = defaultCornerRadius
    private static let contentVerticalInset: CGFloat = 12

    var body: some View {
        Button {
            viewModel.action?()
        } label: {
            HStack(spacing: 4) {
                IconView(url: viewModel.iconURL, size: CGSize(width: 16, height: 16)) {
                    Color.clear
                }

                Text(viewModel.text)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.accent)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, Self.contentVerticalInset + Self.topOverlap)
            .padding(.bottom, Self.contentVerticalInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.Tangem.Markers.backgroundTintedBlue)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(viewModel.action != nil)
        .cornerRadiusContinuous(
            bottomLeadingRadius: Self.defaultCornerRadius,
            bottomTrailingRadius: Self.defaultCornerRadius
        )
        .padding(.top, -Self.topOverlap)
    }
}

enum LinkedMarketingBannerViewModelFactory {
    static func make(
        from banners: [MarketingBanner],
        providerId: String,
        incomingActionHandler: IncomingActionHandler
    ) -> LinkedMarketingBannerViewModel? {
        guard let banner = banners.first(where: { $0.matchesProvider(id: providerId) }) else {
            return nil
        }

        return LinkedMarketingBannerViewModel(
            id: banner.id,
            text: banner.text,
            iconURL: banner.iconURL,
            action: makeAction(for: banner, incomingActionHandler: incomingActionHandler)
        )
    }

    private static func makeAction(
        for banner: MarketingBanner,
        incomingActionHandler: IncomingActionHandler
    ) -> (() -> Void)? {
        switch banner.action {
        case .deeplink(let url):
            return { _ = incomingActionHandler.handleIncomingURL(url) }
        case .none:
            return nil
        }
    }
}
