//
//  TangemPayCampaignCardArtView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

/// Has no local fallback asset on purpose: showing the product's default art in place of the campaign's
/// would misrepresent the campaign, so a failed download offers a retry instead.
struct TangemPayCampaignCardArtView: View {
    let url: URL?
    var cornerRadius: CGFloat = Constants.landingCornerRadius

    /// Only the card being issued is known to be virtual; the landings show generic campaign art.
    var showsDigitalCardIndicator = false

    @State private var reloadCount = 0
    @State private var didFail = false

    static var skeleton: some View {
        Shimmer()
            .variant(
                .custom(
                    width: Constants.width,
                    height: Constants.height,
                    cornerRadius: Constants.landingCornerRadius
                )
            )
    }

    var body: some View {
        content
            .frame(width: Constants.width, height: Constants.height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(alignment: .topLeading) { digitalCardIndicator }
    }

    @ViewBuilder
    private var content: some View {
        if let url {
            if didFail {
                failure
            } else {
                KFImage(url)
                    .forceRefresh(reloadCount > 0)
                    .placeholder { placeholder }
                    .onFailure { _ in didFail = true }
                    .resizable()
                    .scaledToFill()
                    .id(reloadCount)
            }
        } else {
            // Kingfisher never reports a failure for a missing URL, so there is nothing to retry here.
            DesignSystem.Color.bgTransparentSecondary
        }
    }

    @ViewBuilder
    private var digitalCardIndicator: some View {
        if showsDigitalCardIndicator {
            DesignSystem.Icons.Cloud.filled20.image
                .renderingMode(.template)
                .foregroundStyle(.white)
                .padding(Constants.indicatorPadding)
        }
    }

    private var placeholder: some View {
        Shimmer()
            .variant(.custom(cornerRadius: cornerRadius))
    }

    private var failure: some View {
        DesignSystem.Color.bgTransparentSecondary
            .overlay {
                SwiftUI.Button {
                    didFail = false
                    reloadCount += 1
                } label: {
                    DesignSystem.Icons.ArrowRefresh.regular20.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconPrimary)
                        .frame(size: CGSize(bothDimensions: Constants.retryIconSide))
                        .padding(Constants.retryIconPadding)
                        .background(DesignSystem.Color.bgTransparentPrimary, in: .circle)
                }
                .accessibilityLabel(Localization.commonReload)
            }
    }
}

extension TangemPayCampaignCardArtView {
    enum Constants {
        static let width: CGFloat = 266
        static let height: CGFloat = 172

        static let landingCornerRadius: CGFloat = 16
        static let issueCardCornerRadius: CGFloat = 12

        static let retryIconSide: CGFloat = 20
        static let retryIconPadding: CGFloat = 10

        static let indicatorPadding: CGFloat = 12
    }
}
