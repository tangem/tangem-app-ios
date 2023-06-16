//
//  TokenListItemLoadingPlaceholderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenListItemLoadingPlaceholderView: View {
    let iconDimension: CGFloat
    let hasTokenPlaceholder: Bool

    var body: some View {
        ZStack {
            HStack(spacing: 12.0) {
                leadingComponent

                middleComponent

                Spacer()

                trailingComponent
            }
            .padding(.horizontal, 14.0)
            .padding(.vertical, 16.0)
        }
        .background(Colors.Background.primary)
    }

    private var tokenPlaceholderOffset: CGFloat {
        // Values are from Figma mockups
        let iconPlaceholderDimensionToTokenPlaceholderOffsetRatio = 4.0 / 36.0
        return iconDimension * iconPlaceholderDimensionToTokenPlaceholderOffsetRatio
    }

    @ViewBuilder
    private var leadingComponent: some View {
        let iconPlaceholder = SkeletonView()
            .frame(size: .init(bothDimensions: iconDimension))
            .cornerRadius(iconDimension / 2.0)

        if hasTokenPlaceholder {
            iconPlaceholder
                .mask(leadingComponentMask)
                .overlay(leadingComponentTokenPlaceholder, alignment: .topTrailing)
        } else {
            iconPlaceholder
        }
    }

    @ViewBuilder
    private var leadingComponentMask: some View {
        // Values are from Figma mockups
        let iconPlaceholderDimensionToMaskDimensionRatio = 16.0 / 36.0
        let dimension = iconDimension * iconPlaceholderDimensionToMaskDimensionRatio

        ZStack {
            Circle()

            Circle()
                .frame(size: .init(bothDimensions: dimension))
                .offset(x: tokenPlaceholderOffset, y: -tokenPlaceholderOffset)
                .infinityFrame(alignment: .topTrailing)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }

    @ViewBuilder
    private var leadingComponentTokenPlaceholder: some View {
        // Values are from Figma mockups
        let iconPlaceholderDimensionToTokenPlaceholderDimensionRatio = 14.0 / 36.0
        let dimension = iconDimension * iconPlaceholderDimensionToTokenPlaceholderDimensionRatio

        SkeletonView()
            .frame(size: .init(bothDimensions: dimension))
            .cornerRadius(iconDimension / 2.0)
            .offset(x: tokenPlaceholderOffset, y: -tokenPlaceholderOffset)
    }

    @ViewBuilder
    private var middleComponent: some View {
        VStack(alignment: .leading, spacing: 9.0) {
            Group {
                SkeletonView()
                    .frame(width: 70.0, height: 12.0)

                SkeletonView()
                    .frame(width: 52.0, height: 12.0)
            }
            .cornerRadiusContinuous(3.0)
        }
    }

    @ViewBuilder
    private var trailingComponent: some View {
        VStack(spacing: 9.0) {
            Group {
                SkeletonView()

                SkeletonView()
            }
            .frame(width: 40.0, height: 12.0)
            .cornerRadiusContinuous(3.0)
        }
    }
}

// MARK: - Previews

struct TokenListItemLoadingPlaceholderView_Previews: PreviewProvider {
    static let iconDimension = 36.0

    static var previews: some View {
        ZStack {
            Colors.Background
                .secondary
                .ignoresSafeArea()

            VStack {
                TokenListItemLoadingPlaceholderView(
                    iconDimension: iconDimension,
                    hasTokenPlaceholder: false
                )

                TokenListItemLoadingPlaceholderView(
                    iconDimension: iconDimension,
                    hasTokenPlaceholder: true
                )
            }
            .infinityFrame(alignment: .top)
        }
    }
}
