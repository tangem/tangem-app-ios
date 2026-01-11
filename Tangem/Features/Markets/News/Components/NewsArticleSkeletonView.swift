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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Date skeleton
                    SkeletonView()
                        .frame(width: 150, height: 16)
                        .cornerRadius(4)

                    // Title skeleton (2 lines)
                    SkeletonView()
                        .frame(width: geometry.size.width * 0.9 - 32, height: 24)
                        .cornerRadius(6)
                        .padding(.top, 12)

                    SkeletonView()
                        .frame(width: geometry.size.width * 0.55 - 32, height: 24)
                        .cornerRadius(6)
                        .padding(.top, 8)

                    // Tag skeleton (pill shape)
                    SkeletonView()
                        .frame(width: 100, height: 32)
                        .cornerRadius(16)
                        .padding(.top, 16)

                    // Content skeleton lines
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(0 ..< contentLineWidths.count, id: \.self) { index in
                            SkeletonView()
                                .frame(
                                    width: (geometry.size.width - 32) * contentLineWidths[index],
                                    height: 16
                                )
                                .cornerRadius(4)
                        }
                    }
                    .padding(.top, 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
    }
}
