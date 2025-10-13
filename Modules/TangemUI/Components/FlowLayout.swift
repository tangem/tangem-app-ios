//
//  FlowLayout.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

/// Flexible flow layout that arranges items in multiple rows,
/// wrapping to the next line when there is not enough horizontal space.
public struct FlowLayout<Item: Hashable, ItemContent: View>: View {
    private let items: [Item]
    private let horizontalAlignment: HorizontalAlignment
    private let verticalAlignment: VerticalAlignment
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat
    private let itemContent: (Item) -> ItemContent

    @State private var cellsSizes: [CGSize] = []
    @State private var containerWidth: CGFloat = 0

    /// Creates a flow layout view.
    ///
    /// - Parameters:
    ///   - items: The array of items to display in the layout.
    ///   - horizontalAlignment: Horizontal alignment of items within a row (`.leading`, `.center`, `.trailing`).
    ///   - verticalAlignment: Vertical alignment of items inside each row (`.top`, `.center`, `.bottom`).
    ///   - horizontalSpacing: Spacing between items in the same row.
    ///   - verticalSpacing: Spacing between rows.
    ///   - itemContent: A closure that returns a view for each item.
    public init(
        items: [Item],
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        horizontalSpacing: CGFloat = 20,
        verticalSpacing: CGFloat = 20,
        @ViewBuilder itemContent: @escaping (Item) -> ItemContent
    ) {
        self.items = items
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.itemContent = itemContent
    }

    public var body: some View {
        VStack(spacing: 0) {
            containerBoundsAnchorReader
            rowsContent
        }
        .backgroundPreferenceValue(FlowLayoutPreference.self) { anchors in
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        update(anchors: anchors, proxy: proxy)
                    }
                    .onChange(of: anchors) { anchors in
                        update(anchors: anchors, proxy: proxy)
                    }
            }
        }
    }

    /// Split the items into rows depending on their measured sizes and container width
    private func rowRanges() -> [Range<Int>] {
        guard !cellsSizes.isEmpty else {
            // Fallback: single row if we don’t have measurements yet
            return [items.startIndex ..< items.endIndex]
        }

        var result: [Range<Int>] = []
        var rowStartIndex = cellsSizes.startIndex

        while rowStartIndex < cellsSizes.endIndex {
            var currentPositionX: CGFloat = 0
            var rowEndIndex = rowStartIndex

            // Accumulate widths until the next item doesn't fit into the current row
            repeat {
                currentPositionX += cellsSizes[rowEndIndex].width + horizontalSpacing
                rowEndIndex += 1
            } while rowEndIndex < cellsSizes.endIndex && currentPositionX + cellsSizes[rowEndIndex].width < containerWidth

            // Save the range of indices that belong to this row
            result.append(rowStartIndex ..< rowEndIndex)
            rowStartIndex = rowEndIndex
        }

        return result
    }
}

// MARK: - Subviews

private extension FlowLayout {
    var containerBoundsAnchorReader: some View {
        Color.clear
            .frame(height: 0)
            .anchorPreference(
                key: FlowLayoutPreference.self,
                value: .bounds,
                transform: { [FlowLayoutAnchor(anchorType: .container, anchorRect: $0)] }
            )
    }

    var rowsContent: some View {
        VStack(alignment: horizontalAlignment, spacing: verticalSpacing) {
            ForEach(rowRanges(), id: \.self) { rowRange in
                row(range: rowRange)
            }
        }
    }

    func row(range: Range<Int>) -> some View {
        HStack(alignment: verticalAlignment, spacing: horizontalSpacing) {
            ForEach(items[range], id: \.self) { item in
                itemContent(item)
                    .fixedSize()
                    .anchorPreference(
                        key: FlowLayoutPreference.self,
                        value: .bounds,
                        transform: { [FlowLayoutAnchor(anchorType: .cell, anchorRect: $0)] }
                    )
            }
        }
    }

    func update(anchors: [FlowLayoutAnchor], proxy: GeometryProxy) {
        if let containerAnchor = anchors.first(where: { $0.anchorType == .container }) {
            containerWidth = proxy[containerAnchor.anchorRect].width
        }
        cellsSizes = anchors.compactMap {
            guard $0.anchorType == .cell else { return nil }
            return proxy[$0.anchorRect].size
        }
    }
}

private struct FlowLayoutPreference: PreferenceKey {
    typealias Value = [FlowLayoutAnchor]

    static var defaultValue: Value = []

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
}

private struct FlowLayoutAnchor: Hashable {
    let anchorType: AnchorType
    let anchorRect: Anchor<CGRect>

    enum AnchorType {
        case container
        case cell
    }
}

#if DEBUG
#Preview {
    struct Item: Hashable {
        var value: String
    }

    let items = (1 ... 10)
        .map { "Item \($0) " + (Bool.random() ? "\n" : "") + String(repeating: "x", count: Int.random(in: 0 ... 10)) }
        .map(Item.init)

    return FlowLayout(
        items: items,
        horizontalAlignment: .leading,
        verticalAlignment: .center,
        horizontalSpacing: 10,
        verticalSpacing: 20,
        itemContent: { item in
            Text(item.value)
                .padding()
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.blue))
        }
    )
}
#endif
