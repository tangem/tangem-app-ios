//
//  TangemPaginationPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Previews

#if DEBUG

private typealias _Pagination = TangemPagination

// MARK: - Interactive Demo View

private struct PaginationDemoView: View {
    @State private var current: Int = 0
    private let total: Int = 10

    var body: some View {
        VStack(spacing: 8) {
            Text("\(current + 1)/\(total)")
                .font(.headline)

            TangemPagination(totalPages: total, currentIndex: current)

            HStack(spacing: 12) {
                Button("-") {
                    current = max(current - 1, 0)
                }
                .buttonStyle(.bordered)

                Button("+") {
                    current = min(current + 1, total - 1)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - Size Comparison

private struct PaginationDynamicSizesView: View {
    let sizes: [DynamicTypeSize] = [.xSmall, .xxxLarge]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(sizes, id: \.self) { size in
                HStack(spacing: 12) {
                    Text(sizeName(size))

                    PaginationDemoView()
                        .dynamicTypeSize(size)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.2))
    }

    private func sizeName(_ size: DynamicTypeSize) -> String {
        switch size {
        case .xSmall: "xSmall"
        case .xxxLarge: "xxxLarge"
        default: "default"
        }
    }
}

#Preview("Interactive Demo") {
    PaginationDemoView()
}

#Preview("Dark Mode") {
    PaginationDemoView()
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Types") {
    PaginationDynamicSizesView()
}

#endif
