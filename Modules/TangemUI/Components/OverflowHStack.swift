//
//  OverflowHStack.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// A horizontal stack that displays as many items as fit and shows "+N" overflow indicator for the rest.
///
/// Usage:
/// ```swift
/// OverflowHStack(
///     items,
///     spacing: 4,
///     viewGenerator: { item in
///         TagView(title: item.name)
///     },
///     overflowViewGenerator: { count in
///         TagView(title: "+\(count)")
///     }
/// )
/// ```
public struct OverflowHStack<Data: RandomAccessCollection, ItemView: View, OverflowView: View>: View
    where Data.Element: Identifiable, Data.Index == Int {
    private let data: Data
    private let spacing: CGFloat
    private let horizontalAlignment: HorizontalAlignment
    private let verticalAlignment: VerticalAlignment
    private let viewGenerator: (Data.Element) -> ItemView
    private let overflowViewGenerator: (Int) -> OverflowView

    public init(
        _ data: Data,
        spacing: CGFloat = 4,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        @ViewBuilder viewGenerator: @escaping (Data.Element) -> ItemView,
        @ViewBuilder overflowViewGenerator: @escaping (Int) -> OverflowView
    ) {
        self.data = data
        self.spacing = spacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.viewGenerator = viewGenerator
        self.overflowViewGenerator = overflowViewGenerator
    }

    public var body: some View {
        OverflowHStackLayout(spacing: spacing, horizontalAlignment: horizontalAlignment, verticalAlignment: verticalAlignment, itemCount: data.count) {
            ForEach(data) { item in
                viewGenerator(item)
            }

            ForEach(1 ... max(1, data.count), id: \.self) { count in
                overflowViewGenerator(count)
            }
        }
    }
}

// MARK: - OverflowHStackLayout

/// Layout that arranges items horizontally and shows overflow indicator for items that don't fit.
public struct OverflowHStackLayout: Layout {
    public var spacing: CGFloat
    public var horizontalAlignment: HorizontalAlignment
    public var verticalAlignment: VerticalAlignment
    public var itemCount: Int

    public init(
        spacing: CGFloat = 4,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        itemCount: Int
    ) {
        self.spacing = spacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.itemCount = itemCount
    }

    public struct Cache {
        var sizes: [CGSize] = []
    }

    public func makeCache(subviews: Subviews) -> Cache {
        Cache(sizes: subviews.map { $0.sizeThatFits(.unspecified) })
    }

    public func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.sizes = subviews.map { $0.sizeThatFits(.unspecified) }
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        guard itemCount > 0 else { return .zero }

        let availableWidth = proposal.width ?? .infinity
        let maxHeight = cache.sizes.prefix(itemCount).map(\.height).max() ?? 0

        if availableWidth.isFinite {
            return CGSize(width: availableWidth, height: maxHeight)
        }

        let result = calculateLayout(sizes: cache.sizes, availableWidth: availableWidth)

        var totalWidth: CGFloat = 0
        for index in result.visibleIndices {
            if totalWidth > 0 { totalWidth += spacing }
            totalWidth += cache.sizes[index].width
        }

        if result.overflowCount > 0 {
            let overflowIndex = itemCount + result.overflowCount - 1
            if overflowIndex < cache.sizes.count {
                if totalWidth > 0 { totalWidth += spacing }
                totalWidth += cache.sizes[overflowIndex].width
            }
        }

        return CGSize(width: totalWidth, height: maxHeight)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        guard itemCount > 0 else { return }

        let result = calculateLayout(sizes: cache.sizes, availableWidth: bounds.width)

        // Calculate total content width
        var contentWidth: CGFloat = 0
        for index in result.visibleIndices {
            if contentWidth > 0 { contentWidth += spacing }
            contentWidth += cache.sizes[index].width
        }
        if result.overflowCount > 0 {
            let overflowIndex = itemCount + result.overflowCount - 1
            if overflowIndex < cache.sizes.count {
                if contentWidth > 0 { contentWidth += spacing }
                contentWidth += cache.sizes[overflowIndex].width
            }
        }

        var currentX = bounds.minX + xOffset(boundsWidth: bounds.width, contentWidth: contentWidth)

        for index in result.visibleIndices {
            let size = cache.sizes[index]
            let y = yPosition(in: bounds, itemHeight: size.height)
            subviews[index].place(
                at: CGPoint(x: currentX, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            currentX += size.width + spacing
        }

        if result.overflowCount > 0 {
            let overflowIndex = itemCount + result.overflowCount - 1
            if overflowIndex < subviews.count {
                let size = cache.sizes[overflowIndex]
                let y = yPosition(in: bounds, itemHeight: size.height)
                subviews[overflowIndex].place(
                    at: CGPoint(x: currentX, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
            }
        }

        // Hide all non-visible subviews
        for index in subviews.indices {
            let isVisibleItem = result.visibleIndices.contains(index)
            let isActiveOverflow = result.overflowCount > 0 && index == itemCount + result.overflowCount - 1

            if !isVisibleItem, !isActiveOverflow {
                subviews[index].place(
                    at: CGPoint(x: -10000, y: -10000),
                    anchor: .topLeading,
                    proposal: .zero
                )
            }
        }
    }

    // MARK: - Private

    private struct LayoutResult {
        let visibleIndices: [Int]
        let overflowCount: Int
    }

    private func calculateLayout(sizes: [CGSize], availableWidth: CGFloat) -> LayoutResult {
        guard itemCount > 0, !sizes.isEmpty else {
            return LayoutResult(visibleIndices: [], overflowCount: 0)
        }

        // Use the largest overflow width for reservation (worst case)
        let maxOverflowWidth = sizes.dropFirst(itemCount).max(by: { $0.width < $1.width })?.width ?? 0

        var visibleIndices: [Int] = []
        var usedWidth: CGFloat = 0

        for index in 0 ..< itemCount {
            guard index < sizes.count else { break }

            let itemWidth = sizes[index].width
            let remainingItems = itemCount - index - 1

            var requiredWidth = usedWidth
            if !visibleIndices.isEmpty { requiredWidth += spacing }
            requiredWidth += itemWidth

            // Reserve space for overflow indicator if there are more items
            if remainingItems > 0 {
                let overflowSpace = spacing + maxOverflowWidth
                if requiredWidth + overflowSpace > availableWidth {
                    break
                }
            }

            if requiredWidth <= availableWidth {
                visibleIndices.append(index)
                usedWidth = requiredWidth
            } else {
                break
            }
        }

        // Ensure at least one item is shown if possible
        if visibleIndices.isEmpty, itemCount > 0, !sizes.isEmpty {
            visibleIndices = [0]
        }

        let overflowCount = itemCount - visibleIndices.count

        return LayoutResult(visibleIndices: visibleIndices, overflowCount: overflowCount)
    }

    private func xOffset(boundsWidth: CGFloat, contentWidth: CGFloat) -> CGFloat {
        switch horizontalAlignment {
        case .leading:
            return 0
        case .trailing:
            return boundsWidth - contentWidth
        default:
            return (boundsWidth - contentWidth) / 2
        }
    }

    private func yPosition(in bounds: CGRect, itemHeight: CGFloat) -> CGFloat {
        switch verticalAlignment {
        case .top:
            return bounds.minY
        case .bottom:
            return bounds.maxY - itemHeight
        default:
            return bounds.minY + (bounds.height - itemHeight) / 2
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct PreviewItem: Identifiable {
    let id = UUID()
    let title: String
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            Group {
                Text("Few items - all fit")
                    .font(.caption)
                OverflowHStack(
                    [PreviewItem(title: "BTC"), PreviewItem(title: "ETH")],
                    spacing: 4,
                    viewGenerator: { item in
                        Text(item.title)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    },
                    overflowViewGenerator: { count in
                        Text("+\(count)")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                )
                .frame(width: 200)
                .background(Color.gray.opacity(0.1))
            }

            Group {
                Text("Many items - overflow")
                    .font(.caption)
                OverflowHStack(
                    [
                        PreviewItem(title: "Regulation"),
                        PreviewItem(title: "BTC"),
                        PreviewItem(title: "ETH"),
                        PreviewItem(title: "SOL"),
                        PreviewItem(title: "XRP"),
                    ],
                    spacing: 4,
                    viewGenerator: { item in
                        Text(item.title)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    },
                    overflowViewGenerator: { count in
                        Text("+\(count)")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                )
                .frame(width: 200)
                .background(Color.gray.opacity(0.1))
            }

            Group {
                Text("Dynamic width")
                    .font(.caption)
                OverflowHStack(
                    [
                        PreviewItem(title: "News"),
                        PreviewItem(title: "Markets"),
                        PreviewItem(title: "Crypto"),
                        PreviewItem(title: "Finance"),
                    ],
                    spacing: 8,
                    viewGenerator: { item in
                        Text(item.title)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(12)
                    },
                    overflowViewGenerator: { count in
                        Text("+\(count)")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.3))
                            .cornerRadius(12)
                    }
                )
                .background(Color.gray.opacity(0.1))
            }

            Spacer()
        }
        .padding()
    }
}
#endif
