//
//  StorySegmentedProgressBar.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct StorySegmentedProgressBar: View {
    let slides: Int
    let currentIndex: Int
    @ObservedObject var progress: SlideProgress

    private enum Layout {
        static let maxSegmentWidth: CGFloat = 32
        static let height: CGFloat = 6
        static let spacing: CGFloat = 4
    }

    var body: some View {
        GeometryReader { proxy in
            bar(segmentWidth: segmentWidth(in: proxy.size.width))
        }
        .frame(height: Layout.height)
    }

    private func bar(segmentWidth width: CGFloat) -> some View {
        HStack(spacing: Layout.spacing) {
            ForEach(0 ..< slides, id: \.self) { index in
                Capsule()
                    .fill(Colors.Icon.primary1.opacity(0.3))
                    .frame(width: width, height: Layout.height)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Colors.Icon.primary1)
                            .frame(width: width * fill(for: index), height: Layout.height)
                    }
                    .clipped()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func segmentWidth(in available: CGFloat) -> CGFloat {
        guard slides > 0 else { return 0 }
        let gaps = Layout.spacing * CGFloat(slides - 1)
        let fitted = (available - gaps) / CGFloat(slides)
        return max(0, min(Layout.maxSegmentWidth, fitted))
    }

    private func fill(for index: Int) -> Double {
        if index < currentIndex { return 1 }
        if index == currentIndex { return max(0, min(progress.value, 1)) }
        return 0
    }
}
