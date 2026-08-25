//
//  GachaStoriesView+ProgressBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension GachaStoriesView {
    struct ProgressBar: View {
        let slidesCount: Int
        let currentSlideIndex: Int
        let currentSlideProgress: CGFloat

        var body: some View {
            HStack(spacing: Metrics.segmentSpacing) {
                ForEach(0 ..< slidesCount, id: \.self, content: segment)
            }
        }

        private func segment(at index: Int) -> some View {
            Capsule()
                .fill(DesignSystem.Color.bgOpaqueSecondary)
                .frame(width: Metrics.segmentWidth, height: Metrics.segmentHeight)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(DesignSystem.Color.iconPrimary)
                        .frame(width: progress(at: index) * Metrics.segmentWidth)
                }
        }

        private func progress(at index: Int) -> CGFloat {
            if index < currentSlideIndex {
                return 1
            } else if index == currentSlideIndex {
                return currentSlideProgress
            } else {
                return 0
            }
        }
    }
}

// MARK: - Metrics

private extension GachaStoriesView.ProgressBar {
    enum Metrics {
        static let segmentSpacing: CGFloat = 4
        static let segmentWidth: CGFloat = 32
        static let segmentHeight: CGFloat = 6
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        GachaStoriesView.ProgressBar(slidesCount: 5, currentSlideIndex: 1, currentSlideProgress: 0.4)
    }
}
