//
//  NetworkIconOverlayViewModifier.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

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
        overlay(alignment: .topTrailing) {
            NetworkIcon(
                imageAsset: imageAsset,
                isActive: true,
                isMainIndicatorVisible: false,
                size: iconSize
            )
            .shimmer(isEnabled: isShimmerEnabled)
            .background(
                borderColor
                    .clipShape(.circle)
                    .frame(size: iconSize + CGSize(width: 2.0 * borderWidth, height: 2.0 * borderWidth))
            )
            .offset(x: 4.0, y: -4.0)
        }
    }
}
