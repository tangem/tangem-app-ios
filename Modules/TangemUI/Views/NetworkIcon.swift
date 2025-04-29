//
//  NetworkIcon.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct NetworkIcon: View {
    private let imageAsset: ImageType
    private let isActive: Bool
    private var isDisabled: Bool
    private let isMainIndicatorVisible: Bool
    private var size: CGSize

    public var body: some View {
        imageAsset.image
            .resizable()
            .frame(width: size.width, height: size.height)
            .overlay(indicatorOverlay)
            .background(background)
    }

    @ViewBuilder
    private var background: some View {
        if isDisabled {
            Circle()
                .foregroundColor(Colors.Button.disabled)
        } else if !isActive {
            Circle()
                .foregroundColor(Colors.Button.secondary)
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
        size: CGSize = .init(width: 20, height: 20)
    ) {
        self.imageAsset = imageAsset
        self.isActive = isActive
        self.isDisabled = isDisabled
        self.isMainIndicatorVisible = isMainIndicatorVisible
        self.size = size
    }
}

private struct MainNetworkIndicator: View {
    let borderPadding: CGFloat = 1

    var body: some View {
        Circle()
            .foregroundColor(Colors.Icon.accent)
            .padding(borderPadding)
            .background(Circle().fill(Colors.Background.primary))
    }
}

// MARK: - Previews

#if DEBUG
struct NetworkIcon_Previews: PreviewProvider {
    static var previews: some View {
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
        .previewLayout(.sizeThatFits)
    }
}
#endif // DEBUG
