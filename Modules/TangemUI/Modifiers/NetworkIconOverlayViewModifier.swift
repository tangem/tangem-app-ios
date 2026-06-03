//
//  NetworkIconOverlayViewModifier.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemUIUtils

// MARK: - Convenience extensions

public extension View {
    func networkIconOverlay(
        imageAsset: ImageType,
        iconSize: CGSize = .init(bothDimensions: 14.0),
        borderWidth: Double = 2.0,
        borderColor: Color = Colors.Background.primary,
        isShimmerEnabled: Bool = true
    ) -> some View {
        return modifier(
            NetworkIconOverlayViewModifier(
                imageAsset: imageAsset,
                iconSize: iconSize,
                borderWidth: borderWidth,
                borderColor: borderColor,
                isShimmerEnabled: isShimmerEnabled
            )
        )
    }
}

// MARK: - Private implementation

private struct NetworkIconOverlayViewModifier: ViewModifier {
    let imageAsset: ImageType
    let iconSize: CGSize
    let borderWidth: Double
    let borderColor: Color
    let isShimmerEnabled: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                NetworkIcon(
                    imageAsset: imageAsset,
                    isActive: true,
                    isMainIndicatorVisible: false,
                    size: iconSize
                )
                .shimmer(isEnabled: isShimmerEnabled)
                .background(
                    borderColor
                        .clipShape(Circle())
                        .frame(size: iconSize + CGSize(width: 2.0 * borderWidth, height: 2.0 * borderWidth))
                )
                .offset(x: 4.0, y: -4.0)
            }
    }
}
