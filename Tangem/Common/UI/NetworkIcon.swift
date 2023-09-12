//
//  NetworkIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct NetworkIcon: View {
    let imageName: String
    let isActive: Bool
    let isMainIndicatorVisible: Bool
    var size: CGSize = .init(width: 20, height: 20)

    var body: some View {
        Image(imageName)
            .resizable()
            .frame(width: size.width, height: size.height)
            .overlay(indicatorOverlay)
            .background(background)
    }

    @ViewBuilder
    private var background: some View {
        if !isActive {
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
