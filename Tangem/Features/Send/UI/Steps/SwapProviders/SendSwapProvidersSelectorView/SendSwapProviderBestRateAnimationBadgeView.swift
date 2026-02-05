//
//  SendSwapProviderBestRateAnimationBadgeView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct SendSwapProviderBestRateAnimationBadgeView: View {
    @Binding var shouldAnimate: Bool

    @State private var isOpen: Bool = false
    @State private var size: CGSize = .zero
    @State private var animateTask: Task<Void, Never>?

    private let duration: CGFloat = 0.4
    private let lineWidth: CGFloat = 1.5

    var body: some View {
        HStack(alignment: .center, spacing: isOpen ? .zero : 2) {
            icon
                .zIndex(1)

            if isOpen {
                Text(Localization.expressProviderBestRate)
                    .style(Fonts.Bold.caption2, color: Colors.Text.constantWhite)
                    .padding(.trailing, 6)
            }
        }
        .padding(.all, lineWidth)
        .readGeometry(\.frame.size, bindTo: $size)
        .background(
            RoundedRectangle(cornerRadius: size.height / 2, style: .continuous)
                .fill(Colors.Icon.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: size.height / 2, style: .continuous)
                        .stroke(Colors.Background.action, lineWidth: lineWidth)
                )
        )
        .animation(.easeOut(duration: duration), value: isOpen)
        .onAppear(perform: animate)
        .onDisappear {
            animateTask?.cancel()
        }
    }

    private var icon: some View {
        Assets.Express.bestRateStarIcon.image
            .renderingMode(.original)
            .resizable()
            .frame(size: .init(bothDimensions: isOpen ? 10 : 8))
            .padding(.all, isOpen ? 4 : 2)
            .background(Circle().fill(Colors.Icon.accent))
    }

    private func animate() {
        guard shouldAnimate else { return }

        animateTask = Task { @MainActor in
            do {
                // Wait after view is appeared
                try await Task.sleep(for: .seconds(1))
                try Task.checkCancellation()

                isOpen = true
                shouldAnimate = false
                try await Task.sleep(for: .seconds(1.5))
                isOpen = false
            } catch {
                isOpen = false
            }
        }
    }
}
