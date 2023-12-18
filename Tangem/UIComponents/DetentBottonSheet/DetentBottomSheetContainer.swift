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

extension DetentBottomSheetContainer {
    enum Detent: Hashable {
        case medium
        case large
        case custom(CGFloat)
        case fraction(CGFloat)

        @available(iOS 16.0, *)
        var detentsAbove_16_4: PresentationDetent {
            switch self {
            case .large:
                return PresentationDetent.large
            case .medium:
                return PresentationDetent.medium
            case .custom(let height):
                return .height(height)
            case .fraction(let value):
                return .fraction(value)
            }
        }
    }

    struct Settings {
        let cornerRadius: CGFloat
        let backgroundColor: Color
        let animationDuration: Double

        init(
            cornerRadius: CGFloat = 24,
            backgroundColor: Color = Colors.Background.secondary,
            animationDuration: Double = 0.35
        ) {
            self.cornerRadius = cornerRadius
            self.backgroundColor = backgroundColor
            self.animationDuration = animationDuration
        }
    }
}
