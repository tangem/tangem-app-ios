//
//  View+NetworkOverlay.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemFoundation

// MARK: - Convenience extensions

extension View {
    func networkOverlay(
        image: Image,
        offset: CGSize
    ) -> some View {
        modifier(NetworkOverlayViewModifier(image: image, offset: offset))
    }
}

// MARK: - Private implementation

private struct NetworkOverlayViewModifier: ViewModifier {
    let image: Image
    let offset: CGSize

    func body(content: Content) -> some View {
        let size = CGSize(bothDimensions: 14.0)

        content
            .overlay(alignment: .topTrailing) {
                image
                    .resizable()
                    .frame(size: size)
                    .stroked(
                        color: Colors.Background.primary,
                        cornerRadius: size.width / 2.0,
                        lineWidth: 2.0
                    )
                    .offset(offset)
            }
    }
}
