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
    let isMainIndicatorVisible: Bool
    var size: CGSize = .init(width: 20, height: 20)

    var body: some View {
        Image(imageName)
            .resizable()
            .frame(width: size.width, height: size.height)
            .overlay(indicatorOverlay)
    }

    @ViewBuilder
    private var indicatorOverlay: some View {
        if isMainIndicatorVisible {
            let indicatorSize: CGSize = .init(width: size.width / 3, height: size.height / 3)
            MainNetworkIndicator()
                .frame(width: indicatorSize.width, height: indicatorSize.height)
                .offset(
                    x: size.width / 2 - indicatorSize.width / 2,
                    y: -size.height / 2 + indicatorSize.height / 2
                )
        } else {
            EmptyView()
        }
    }
}

private struct MainNetworkIndicator: View {
    let borderPadding: CGFloat = 1.5

    var body: some View {
        Circle()
            .foregroundColor(Colors.Icon.accent)
            .padding(borderPadding)
            .background(Circle().fill(Colors.Background.primary))
    }
}
