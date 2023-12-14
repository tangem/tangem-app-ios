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
        case medium // @available(iOS 15.0 *)
        case large // @available(iOS 15.0 *)
        case custom(CGFloat) // @available(iOS 16.4 *)

        @available(iOS 16.0, *)
        var detentsAbove_16_4: PresentationDetent {
            switch self {
            case .large:
                return PresentationDetent.large
            case .medium:
                return PresentationDetent.medium
            case .custom(let height):
                return .height(height)
            }
        }

        @available(iOS 15.0, *)
        var detentsAbove_15_0: UISheetPresentationController.Detent {
            switch self {
            case .large:
                return .large()
            case .medium:
                return .medium()
            default:
                return .large()
            }
        }
    }

    struct Settings {
        let detents: Set<Detent>
        let cornerRadius: CGFloat
        let backgroundColor: Color
        let animationDuration: Double

        init(
            detents: Set<Detent> = [.large],
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
