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
    enum Style {
        case tokenList(hasNetworkItemPlaceholder: Bool)
        case transactionHistory
    }

    let style: Style

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
        .background(Colors.Background.primary)
    }

    private var iconDimension: CGFloat {
        switch style {
        case .tokenList:
            return 36.0
        case .transactionHistory:
            return 40.0
        }
    }

    private var height: CGFloat {
        switch style {
        case .tokenList:
            return 68.0
        case .transactionHistory:
            return 56.0
        }
    }

    private var hasNetworkItemPlaceholder: Bool {
        if case .tokenList(let hasNetworkItemPlaceholder) = style {
            return hasNetworkItemPlaceholder
        }
        return false
    }

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
        Colors.Background
            .secondary
            .ignoresSafeArea()

        VStack {
            TokenListItemLoadingPlaceholderView(
                style: .tokenList(hasNetworkItemPlaceholder: false)
            )

            TokenListItemLoadingPlaceholderView(
                style: .tokenList(hasNetworkItemPlaceholder: true)
            )

            TokenListItemLoadingPlaceholderView(
                style: .transactionHistory
            )
        }
        .infinityFrame(alignment: .top)
    }
}
