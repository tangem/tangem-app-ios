//
//  TokenListItemLoadingPlaceholderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TokenListItemLoadingPlaceholderView: View {
    let hasNetworkItemPlaceholder: Bool

    var body: some View {
        ZStack {
            HStack(spacing: 12.0) {
                leadingComponent

                middleComponent

                Spacer()

                trailingComponent
            }
            .frame(height: height)
            .padding(.horizontal, 14.0)
        }
        .background(DesignSystem.Color.bgSecondary)
    }

    private var iconDimension: CGFloat { 36.0 }

    private var height: CGFloat { 68.0 }

    private var networkItemPlaceholderOffset: CGFloat { 4 }

    @ViewBuilder
    private var leadingComponent: some View {
        let iconPlaceholder = Shimmer()
            .variant(.custom(width: iconDimension, height: iconDimension))

        if hasNetworkItemPlaceholder {
            iconPlaceholder
                .mask(leadingComponentMask)
                .overlay(leadingComponentNetworkItemPlaceholder, alignment: .topTrailing)
        } else {
            iconPlaceholder
        }
    }

    @ViewBuilder
    private var leadingComponentMask: some View {
        let dimension = 16.0

        ZStack {
            Circle()

            Circle()
                .frame(size: .init(bothDimensions: dimension))
                .offset(x: networkItemPlaceholderOffset, y: -networkItemPlaceholderOffset)
                .infinityFrame(alignment: .topTrailing)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }

    @ViewBuilder
    private var leadingComponentNetworkItemPlaceholder: some View {
        let dimension = 14.0

        Shimmer()
            .variant(.custom(width: dimension, height: dimension))
            .offset(x: networkItemPlaceholderOffset, y: -networkItemPlaceholderOffset)
    }

    @ViewBuilder
    private var middleComponent: some View {
        VStack(alignment: .leading, spacing: 9.0) {
            Shimmer().variant(.custom(width: 70.0, height: 12.0, cornerRadius: 3.0))

            Shimmer().variant(.custom(width: 52.0, height: 12.0, cornerRadius: 3.0))
        }
    }

    @ViewBuilder
    private var trailingComponent: some View {
        VStack(spacing: 9.0) {
            Shimmer().variant(.custom(width: 40.0, height: 12.0, cornerRadius: 3.0))

            Shimmer().variant(.custom(width: 40.0, height: 12.0, cornerRadius: 3.0))
        }
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary
            .ignoresSafeArea()

        VStack {
            TokenListItemLoadingPlaceholderView(
                hasNetworkItemPlaceholder: false
            )

            TokenListItemLoadingPlaceholderView(
                hasNetworkItemPlaceholder: true
            )
        }
        .infinityFrame(alignment: .top)
    }
}
