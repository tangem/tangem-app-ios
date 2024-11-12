//
//  MarketsTokenDetailsSecurityScoreRatingView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 07.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsSecurityScoreRatingView: View {
    let viewData: MarketsTokenDetailsSecurityScoreRatingViewData

    var body: some View {
        HStack(spacing: 6.0) {
            Text(viewData.securityScore)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

            ForEach(viewData.ratingBullets.indexed(), id: \.0) { _, ratingBullet in
                RatingBulletView(ratingBullet: ratingBullet)
            }
        }
    }
}

// MARK: - Auxiliary types

private extension MarketsTokenDetailsSecurityScoreRatingView {
    struct RatingBulletView: View {
        let ratingBullet: MarketsTokenDetailsSecurityScoreRatingViewData.RatingBullet

        var body: some View {
            ZStack {
                makeAsset(Assets.starThickFill)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(
                                width: Constants.ratingViewDimensions.width * ratingBullet.value,
                                height: Constants.ratingViewDimensions.height
                            )
                    }

                makeAsset(Assets.starThick)
            }
        }

        @ViewBuilder
        private func makeAsset(_ imageType: ImageType) -> some View {
            imageType
                .image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.accent)
                .frame(size: Constants.ratingViewDimensions)
        }
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsSecurityScoreRatingView {
    enum Constants {
        static let ratingViewDimensions = CGSize(bothDimensions: 14.0)
    }
}

// MARK: - Previews

#Preview {
    // TODO: Andrey Fedorov - Add actual implementation
//    MarketsTokenDetailsSecurityScoreRatingView(ratingBullet: .init(value: 1.0), dimensions: .init(bothDimensions: 24.0))

//    MarketsTokenDetailsSecurityScoreRatingView(ratingBullet: .init(value: 0.4), dimensions: .init(bothDimensions: 24.0))

//    MarketsTokenDetailsSecurityScoreRatingView(ratingBullet: .init(value: 0.1), dimensions: .init(bothDimensions: 24.0))
}
