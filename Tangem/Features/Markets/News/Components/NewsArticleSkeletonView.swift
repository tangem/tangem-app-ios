//
//  NewsArticleSkeletonView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct NewsArticleSkeletonView: View {
    private let contentLineWidths: [CGFloat] = [1.0, 0.78, 0.85, 0.68, 0.80, 1.0]

    var body: some View {
        GeometryReader { geometry in
            ContentView(
                contentWidth: geometry.size.width,
                contentLineWidths: contentLineWidths
            )
        }
    }
}

private extension NewsArticleSkeletonView {
    struct ContentView: View {
        let contentWidth: CGFloat
        let contentLineWidths: [CGFloat]

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    dateSkeleton

                    titleSkeleton

                    tagSkeleton

                    contentSkeletonLines
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)
        }

        private var dateSkeleton: some View {
            SkeletonView()
                .frame(width: 150, height: 16)
                .cornerRadius(4)
        }

        private var titleSkeleton: some View {
            VStack(alignment: .leading, spacing: 0) {
                SkeletonView()
                    .frame(width: contentWidth * 0.9 - 32, height: 24)
                    .cornerRadius(6)
                    .padding(.top, 12)

                SkeletonView()
                    .frame(width: contentWidth * 0.55 - 32, height: 24)
                    .cornerRadius(6)
                    .padding(.top, 8)
            }
        }

        private var tagSkeleton: some View {
            SkeletonView()
                .frame(width: 100, height: 32)
                .cornerRadius(16)
                .padding(.top, 16)
        }

        private var contentSkeletonLines: some View {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0 ..< contentLineWidths.count, id: \.self) { index in
                    SkeletonView()
                        .frame(
                            width: (contentWidth - 32) * contentLineWidths[index],
                            height: 16
                        )
                        .cornerRadius(4)
                }
            }
            .padding(.top, 32)
        }
    }
}
