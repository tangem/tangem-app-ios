//
//  NetworkIcon.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct NetworkIcon: View {
    private let imageAsset: ImageType
    private let isActive: Bool
    private var isDisabled: Bool
    private let showBackground: Bool
    private let isMainIndicatorVisible: Bool
    private var size: CGSize

    public var body: some View {
        imageAsset.image
            .resizable()
            .frame(width: size.width, height: size.height)
            .overlay(indicatorOverlay)
            .if(showBackground) { $0.background(background) }
    }

    @ViewBuilder
    private var background: some View {
        if isDisabled {
            Circle()
                .foregroundColor(DesignSystem.Color.bgDisabled)
        } else if !isActive {
            Circle()
                .foregroundColor(DesignSystem.Color.bgTransparentSecondary)
        }
    }

    @ViewBuilder
    private var indicatorOverlay: some View {
        if isMainIndicatorVisible {
            let indicatorSize: CGSize = .init(width: 6, height: 6)
            let radius = size.width / 2
            let indicatorDistance = radius * sin(Double.pi / 4)

            MainNetworkIndicator()
                .frame(width: indicatorSize.width, height: indicatorSize.height)
                .offset(
                    x: indicatorDistance,
                    y: -indicatorDistance
                )
        } else {
            EmptyView()
        }
    }

    public init(
        imageAsset: ImageType,
        isActive: Bool,
        isDisabled: Bool = false,
        isMainIndicatorVisible: Bool,
        showBackground: Bool = true,
        size: CGSize = .init(width: 20, height: 20)
    ) {
        self.imageAsset = imageAsset
        self.isActive = isActive
        self.isDisabled = isDisabled
        self.isMainIndicatorVisible = isMainIndicatorVisible
        self.showBackground = showBackground
        self.size = size
    }
}

private struct MainNetworkIndicator: View {
    let borderPadding: CGFloat = 1

    var body: some View {
        Circle()
            .foregroundColor(DesignSystem.Color.iconAccentBlue)
            .padding(borderPadding)
            .background(Circle().fill(DesignSystem.Color.bgSecondary))
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    VStack {
        NetworkIcon(imageAsset: Tokens.solanaFill, isActive: true, isMainIndicatorVisible: true)

        NetworkIcon(
            imageAsset: Tokens.solanaFill,
            isActive: true,
            isDisabled: false,
            isMainIndicatorVisible: true,
            size: CGSize(bothDimensions: 36)
        )
    }
    .padding()
}
