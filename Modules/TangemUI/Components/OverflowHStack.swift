//
//  OverflowHStack.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// A horizontal stack that wraps items to multiple lines with optional overflow indicator.
///
/// Usage:
/// ```swift
/// // Default: wraps all items
/// OverflowHStack(items) { item in
///     TagView(title: item.name)
/// }
///
/// // Single line with "+N" overflow
/// OverflowHStack(items, lineLimit: 1) { item in
///     TagView(title: item.name)
/// } limitViewGenerator: { count in
///     TagView(title: "+\(count)")
/// }
/// ```
public struct OverflowHStack<Data: RandomAccessCollection, ItemView: View, LimitView: View>: View
    where Data.Element: Identifiable, Data.Index == Int {
    private let data: Data
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat
    private let horizontalAlignment: HorizontalAlignment
    private let verticalAlignment: VerticalAlignment
    private let lineLimit: Int?
    private let viewGenerator: (Data.Element) -> ItemView
    private let limitViewGenerator: (Int) -> LimitView

    /// Creates an OverflowHStack.
    /// - Parameters:
    ///   - data: The collection of items to display.
    ///   - horizontalSpacing: Horizontal spacing between items (default: 4).
    ///   - verticalSpacing: Vertical spacing between rows (default: 4).
    ///   - horizontalAlignment: Horizontal alignment of rows (default: .leading).
    ///   - verticalAlignment: Vertical alignment of items within a row (default: .center).
    ///   - lineLimit: Maximum number of lines. Use `nil` for unlimited (default: nil).
    ///   - viewGenerator: Closure to create view for each item.
    ///   - limitViewGenerator: Closure to create overflow indicator view for a given count.
    public init(
        _ data: Data,
        horizontalSpacing: CGFloat = 4,
        verticalSpacing: CGFloat = 4,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        lineLimit: Int? = nil,
        @ViewBuilder viewGenerator: @escaping (Data.Element) -> ItemView,
        @ViewBuilder limitViewGenerator: @escaping (Int) -> LimitView = { _ in EmptyView() }
    ) {
        self.data = data
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.lineLimit = lineLimit
        self.viewGenerator = viewGenerator
        self.limitViewGenerator = limitViewGenerator
    }

    public var body: some View {
        let effectiveLineLimit = lineLimit.map { max(1, $0) }

        OverflowHStackLayout(
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            itemCount: data.count,
            lineLimit: effectiveLineLimit
        ) {
            ForEach(data) { item in
                viewGenerator(item)
            }

            if effectiveLineLimit != nil, !data.isEmpty {
                ForEach(1 ... data.count, id: \.self) { count in
                    limitViewGenerator(count)
                }
            }
        }
    }
}

// MARK: - OverflowHStackLayout

/// Layout that arranges items horizontally with wrapping and optional overflow indicator.
public struct OverflowHStackLayout: Layout {
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat
    public var horizontalAlignment: HorizontalAlignment
    public var verticalAlignment: VerticalAlignment
    public var itemCount: Int
    public var lineLimit: Int?

    public init(
        horizontalSpacing: CGFloat = 4,
        verticalSpacing: CGFloat = 4,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        itemCount: Int,
        lineLimit: Int? = nil
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.itemCount = itemCount
        self.lineLimit = lineLimit
    }

    public struct Cache {
        var sizes: [CGSize] = []
        var layoutResult: (hash: Int, result: LayoutResult)?
    }

    public func makeCache(subviews: Subviews) -> Cache {
        Cache(sizes: subviews.map { $0.sizeThatFits(.unspecified) })
    }

    public func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        cache.layoutResult = nil
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        guard itemCount > 0 else { return .zero }

        let availableWidth = proposal.width ?? .infinity
        let result = cachedLayout(availableWidth: availableWidth, cache: &cache)

        if result.lines.isEmpty { return .zero }

        var width: CGFloat = result.lines.map(\.width).max() ?? 0
        if availableWidth.isFinite {
            width = availableWidth
        }

        let height = result.lines.last.map { $0.yOffset + $0.height } ?? 0

        return CGSize(width: width, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        guard itemCount > 0 else { return }

        let result = cachedLayout(availableWidth: bounds.width, cache: &cache)

        // Place visible items
        for (lineIndex, line) in result.lines.enumerated() {
            let lineXOffset = xOffset(boundsWidth: bounds.width, contentWidth: line.width)
            let isLastLine = lineIndex == result.lines.count - 1

            for element in line.elements {
                let x = bounds.minX + lineXOffset + element.xOffset
                let y = bounds.minY + line.yOffset + yOffset(lineHeight: line.height, itemHeight: element.size.height)
                subviews[element.index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(element.size)
                )
            }

            // Place limit indicator on last line if needed
            if isLastLine, result.limitCount > 0 {
                let limitIndex = itemCount + result.limitCount - 1
                if limitIndex < subviews.count {
                    let size = cache.sizes[limitIndex]
                    let x = bounds.minX + lineXOffset + line.contentWidth + horizontalSpacing
                    let y = bounds.minY + line.yOffset + yOffset(lineHeight: line.height, itemHeight: size.height)
                    subviews[limitIndex].place(
                        at: CGPoint(x: x, y: y),
                        anchor: .topLeading,
                        proposal: ProposedViewSize(size)
                    )
                }
            }
        }

        // Hide all non-visible subviews
        let activeLimitIndex = result.limitCount > 0 ? itemCount + result.limitCount - 1 : -1

        for index in subviews.indices {
            if !result.visibleIndices.contains(index), index != activeLimitIndex {
                subviews[index].place(
                    at: CGPoint(x: -10000, y: -10000),
                    anchor: .topLeading,
                    proposal: .zero
                )
            }
        }
    }

    // MARK: - Private

    struct LineElement {
        let index: Int
        let size: CGSize
        let xOffset: CGFloat
    }

    struct Line {
        var elements: [LineElement] = []
        var yOffset: CGFloat = 0
        var contentWidth: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    struct LayoutResult {
        let lines: [Line]
        let limitCount: Int
        let visibleIndices: Set<Int>
    }

    private func cachedLayout(availableWidth: CGFloat, cache: inout Cache) -> LayoutResult {
        let hash = computeHash(availableWidth: availableWidth, sizes: cache.sizes)

        if let cached = cache.layoutResult, cached.hash == hash {
            return cached.result
        }

        let result = calculateLayout(sizes: cache.sizes, availableWidth: availableWidth)
        cache.layoutResult = (hash, result)
        return result
    }

    private func computeHash(availableWidth: CGFloat, sizes: [CGSize]) -> Int {
        var hasher = Hasher()
        hasher.combine(availableWidth.isFinite ? availableWidth : -1)
        hasher.combine(itemCount)
        hasher.combine(lineLimit)
        for size in sizes.prefix(itemCount) {
            hasher.combine(size.width)
            hasher.combine(size.height)
        }
        return hasher.finalize()
    }

    private func calculateLayout(sizes: [CGSize], availableWidth: CGFloat) -> LayoutResult {
        guard itemCount > 0, !sizes.isEmpty else {
            return LayoutResult(lines: [], limitCount: 0, visibleIndices: [])
        }

        let effectiveLineLimit = lineLimit ?? itemCount
        let hasLineLimit = lineLimit != nil

        // Get max limit indicator width for space reservation
        let maxLimitWidth: CGFloat
        if hasLineLimit {
            maxLimitWidth = sizes.dropFirst(itemCount).max(by: { $0.width < $1.width })?.width ?? 0
        } else {
            maxLimitWidth = 0
        }

        var lines: [Line] = []
        var currentLine = Line()
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var processedCount = 0

        for index in 0 ..< itemCount {
            guard index < sizes.count else { break }

            let itemSize = sizes[index]
            let needsSpacing = !currentLine.elements.isEmpty
            let itemX = currentX + (needsSpacing ? horizontalSpacing : 0)
            let itemEndX = itemX + itemSize.width

            // Check if item fits in current line
            var fitsInLine = itemEndX <= availableWidth || currentLine.elements.isEmpty

            // If we're at line limit, reserve space for limit indicator
            if hasLineLimit, fitsInLine, lines.count + 1 >= effectiveLineLimit {
                let remainingItems = itemCount - index - 1
                if remainingItems > 0 {
                    let limitSpace = horizontalSpacing + maxLimitWidth
                    if itemEndX + limitSpace > availableWidth {
                        fitsInLine = false
                    }
                }
            }

            if fitsInLine {
                // Add item to current line
                currentLine.elements.append(LineElement(index: index, size: itemSize, xOffset: itemX))
                currentLine.height = max(currentLine.height, itemSize.height)
                currentLine.contentWidth = itemEndX
                currentLine.width = itemEndX
                currentX = itemEndX
                processedCount = index + 1
            } else if hasLineLimit, lines.count + 1 >= effectiveLineLimit {
                // At line limit, stop here
                break
            } else {
                // Start new line
                if !currentLine.elements.isEmpty {
                    currentLine.yOffset = currentY
                    lines.append(currentLine)
                    currentY += currentLine.height + verticalSpacing
                }

                currentLine = Line()
                currentLine.elements.append(LineElement(index: index, size: itemSize, xOffset: 0))
                currentLine.height = itemSize.height
                currentLine.contentWidth = itemSize.width
                currentLine.width = itemSize.width
                currentX = itemSize.width
                processedCount = index + 1
            }
        }

        // Finalize last line
        if !currentLine.elements.isEmpty {
            currentLine.yOffset = currentY
            lines.append(currentLine)
        }

        let limitCount = hasLineLimit ? (itemCount - processedCount) : 0

        // Adjust last line width to include limit indicator
        if limitCount > 0, !lines.isEmpty {
            let limitSize = sizes[itemCount + limitCount - 1]
            lines[lines.count - 1].width = lines[lines.count - 1].contentWidth + horizontalSpacing + limitSize.width
            lines[lines.count - 1].height = max(lines[lines.count - 1].height, limitSize.height)
        }

        // Build visible indices set
        var visibleIndices = Set<Int>()
        visibleIndices.reserveCapacity(processedCount)
        for line in lines {
            for element in line.elements {
                visibleIndices.insert(element.index)
            }
        }

        return LayoutResult(lines: lines, limitCount: limitCount, visibleIndices: visibleIndices)
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

    private func yOffset(lineHeight: CGFloat, itemHeight: CGFloat) -> CGFloat {
        switch verticalAlignment {
        case .top:
            return 0
        case .bottom:
            return lineHeight - itemHeight
        default:
            return (lineHeight - itemHeight) / 2
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
                Text("Default (wraps all)")
                    .font(.caption)
                OverflowHStack(
                    [
                        PreviewItem(title: "Regulation"),
                        PreviewItem(title: "BTC"),
                        PreviewItem(title: "ETH"),
                        PreviewItem(title: "SOL"),
                        PreviewItem(title: "XRP"),
                    ],
                    horizontalSpacing: 4,
                    verticalSpacing: 4
                ) { item in
                    Text(item.title)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
                .frame(width: 200)
                .background(Color.gray.opacity(0.1))
            }

            Group {
                Text("lineLimit: 1 (with +N)")
                    .font(.caption)
                OverflowHStack(
                    [
                        PreviewItem(title: "Regulation"),
                        PreviewItem(title: "BTC"),
                        PreviewItem(title: "ETH"),
                        PreviewItem(title: "SOL"),
                        PreviewItem(title: "XRP"),
                    ],
                    horizontalSpacing: 4,
                    verticalSpacing: 4,
                    lineLimit: 1
                ) { item in
                    Text(item.title)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                } limitViewGenerator: { count in
                    Text("+\(count)")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                }
                .frame(width: 200)
                .background(Color.gray.opacity(0.1))
            }

            Group {
                Text("lineLimit: 2 (with +N)")
                    .font(.caption)
                OverflowHStack(
                    [
                        PreviewItem(title: "News"),
                        PreviewItem(title: "Markets"),
                        PreviewItem(title: "Crypto"),
                        PreviewItem(title: "Finance"),
                        PreviewItem(title: "Trading"),
                        PreviewItem(title: "Analysis"),
                    ],
                    horizontalSpacing: 4,
                    verticalSpacing: 4,
                    lineLimit: 2
                ) { item in
                    Text(item.title)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                } limitViewGenerator: { count in
                    Text("+\(count)")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                }
                .frame(width: 200)
                .background(Color.gray.opacity(0.1))
            }

            Spacer()
        }
        .padding()
    }
}
#endif
