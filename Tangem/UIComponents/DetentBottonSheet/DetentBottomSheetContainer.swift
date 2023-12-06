//
//  DetentBottomSheetContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

@available(iOS 15.0, *)
struct DetentBottomSheetContainer<ContentView: View>: View {
    private let settings: Settings
    private let content: () -> ContentView

    // MARK: - Internal

    private let indicatorSize = CGSize(width: 32, height: 4)

    init(
        settings: Settings,
        content: @escaping () -> ContentView
    ) {
        self.settings = settings
        self.content = content
    }

    var body: some View {
        sheetView
    }

    private var sheetView: some View {
        VStack(spacing: 0) {
            indicator

            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(settings.backgroundColor)
    }

    private var indicator: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Colors.Icon.inactive)
                .frame(size: indicatorSize)
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .background(settings.backgroundColor)
    }
}

// MARK: - Settings

@available(iOS 15.0, *)
extension DetentBottomSheetContainer {
    enum Detent {
        case medium
        case large
        case custom(CGFloat)
    }

    struct Settings {
        let detents: [Detent]
        let cornerRadius: CGFloat
        let backgroundColor: Color
        let animationDuration: Double

        init(
            detents: [Detent] = [.large],
            cornerRadius: CGFloat = 24,
            backgroundColor: Color = Colors.Background.secondary,
            animationDuration: Double = 0.35
        ) {
            self.detents = detents
            self.cornerRadius = cornerRadius
            self.backgroundColor = backgroundColor
            self.animationDuration = animationDuration
        }
    }
}
