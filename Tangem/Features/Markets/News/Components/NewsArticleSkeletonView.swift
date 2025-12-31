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
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                // Header skeleton
                HStack(spacing: 4) {
                    SkeletonView()
                        .frame(width: 50, height: 14)
                        .cornerRadius(4)
                    SkeletonView()
                        .frame(width: 60, height: 14)
                        .cornerRadius(4)
                }

                // Title skeleton
                SkeletonView()
                    .frame(height: 24)
                    .cornerRadius(4)
                SkeletonView()
                    .frame(width: 200, height: 24)
                    .cornerRadius(4)

                // Tags skeleton
                HStack(spacing: 4) {
                    SkeletonView()
                        .frame(width: 80, height: 28)
                        .cornerRadius(14)
                    SkeletonView()
                        .frame(width: 60, height: 28)
                        .cornerRadius(14)
                }
                .padding(.top, 8)

                // Quick recap skeleton
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonView()
                        .frame(width: 100, height: 16)
                        .cornerRadius(4)
                    SkeletonView()
                        .frame(height: 60)
                        .cornerRadius(4)
                }
                .padding(.top, 20)

                // Content skeleton
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(0 ..< 8, id: \.self) { _ in
                        SkeletonView()
                            .frame(height: 16)
                            .cornerRadius(4)
                    }
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
}
