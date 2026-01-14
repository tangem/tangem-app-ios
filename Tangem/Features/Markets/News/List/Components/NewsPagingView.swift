//
//  NewsPagingView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

/// Horizontal pager for swiping between news cards (Apple Stocks-like behavior)
struct NewsPagingView<Content: View>: View {
    @Binding var currentIndex: Int
    let pageCount: Int
    let onPageChange: ((Int) -> Void)?
    @ViewBuilder let content: () -> Content

    @GestureState private var translation: CGFloat = 0

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    content()
                        .frame(width: geometry.size.width)
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .offset(x: -CGFloat(currentIndex) * geometry.size.width)
                .offset(x: translation)
                .animation(.interactiveSpring(), value: currentIndex)
                .gesture(
                    DragGesture()
                        .updating($translation) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            let offset = value.translation.width / geometry.size.width
                            let predictedOffset = value.predictedEndTranslation.width / geometry.size.width

                            // Use predicted offset for velocity-based page change
                            let effectiveOffset = abs(predictedOffset) > 0.5 ? predictedOffset : offset
                            let newIndex = (CGFloat(currentIndex) - effectiveOffset).rounded()

                            let clampedIndex = max(0, min(Int(newIndex), pageCount - 1))

                            if clampedIndex != currentIndex {
                                currentIndex = clampedIndex
                                onPageChange?(currentIndex)
                            }
                        }
                )
            }

            if pageCount > 1 {
                PageIndicatorView(totalPages: pageCount, currentIndex: currentIndex)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 17.0, *)
#Preview("NewsPagingView") {
    @Previewable @State var currentIndex = 0

    NewsPagingView(
        currentIndex: $currentIndex,
        pageCount: 5,
        onPageChange: nil
    ) {
        ForEach(0 ..< 5) { index in
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.blue.opacity(0.3))
                .overlay(Text("Page \(index + 1)"))
        }
    }
    .frame(height: 200)
    .padding()
}
#endif
