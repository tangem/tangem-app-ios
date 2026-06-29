//
//  TangemCarousel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemUIUtils

/// A horizontal pager with optional endless scrolling.
///
/// When `isEndless` is `true` (default) the view uses the boundary-duplicate
/// technique: the last item is prepended and the first item is appended so
/// the user can swipe continuously in either direction.
/// When `isEndless` is `false` the index is clamped at boundaries.
public struct TangemCarousel<Data, Content>: View
    where Data: RandomAccessCollection, Data.Element: Hashable, Data.Element: Identifiable, Content: View {
    private let data: Data
    private let content: (Data.Element) -> Content

    private let animationDuration: TimeInterval = 0.3

    private var isEndless: Bool = false
    private var interItemSpacing: CGFloat = 0
    private var hidePagination: Bool = false
    private var paginationHasBackground: Bool = false
    private var currentIndexHasChanged: ((Int) -> Void)?
    private var onTranslationChanged: ((CGFloat) -> Void)?

    @State private var currentIndex: Int
    @GestureState private var translation: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    // MARK: - Init

    public init(
        _ data: Data,
        initialIndex: Int = 0,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
        let maxIndex = max(data.count - 1, 0)
        _currentIndex = State(initialValue: clamp(initialIndex, min: 0, max: maxIndex))
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: SizeUnit.x4.value) {
            pages

            if !hidePagination, data.count > 1 {
                TangemPagination(
                    totalPages: data.count,
                    currentIndex: externalIndex,
                    hasBackground: paginationHasBackground
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { containerWidth = $0 }
        .onChange(of: data.count) { _ in
            let maxIndex = max(data.count - 1, 0)
            let clamped = clamp(currentIndex, min: 0, max: maxIndex)
            if currentIndex != clamped {
                currentIndex = clamped
            }
        }
        .onChange(of: externalIndex) { currentIndexHasChanged?($0) }
    }
}

// MARK: - Subviews

private extension TangemCarousel {
    @ViewBuilder
    var pages: some View {
        if containerWidth > 0, data.isNotEmpty {
            scrollableContent
                .onChange(of: translation) { onTranslationChanged?($0) }
        } else if let currentElement {
            // Gives the carousel its real height on the first layout pass; otherwise an enclosing
            // animated container shows the 0 -> full height jump as a collapse-then-grow.
            content(currentElement)
                .frame(maxWidth: .infinity)
        }
    }

    var currentElement: Data.Element? {
        guard data.isNotEmpty else { return nil }
        let index = clamp(externalIndex, min: 0, max: data.count - 1)
        return data[data.index(data.startIndex, offsetBy: index)]
    }

    var scrollableContent: some View {
        let items = displayItems
        let baseIndex = isEndless ? currentIndex + 1 : currentIndex

        return HStack(alignment: .top, spacing: interItemSpacing) {
            ForEach(items, id: \.id) { item in
                content(item.element)
                    .frame(width: containerWidth)
                    // Once a drag passes the gesture's slop, disable the content so an
                    // in-flight press (e.g. a banner button) is canceled and a swipe started
                    // on a button never fires it. A pure tap keeps translation at 0.
                    .disabled(translation != 0)
            }
        }
        .frame(width: containerWidth, alignment: .leading)
        .offset(x: -CGFloat(baseIndex) * pageStep)
        .offset(x: effectiveTranslation)
        .animation(.easeOut(duration: animationDuration), value: translation)
        .if(data.count > 1) { $0.simultaneousGesture(dragGesture) }
    }
}

// MARK: - Gesture

private extension TangemCarousel {
    var pageStep: CGFloat {
        containerWidth + interItemSpacing
    }

    var effectiveTranslation: CGFloat {
        guard !isEndless else { return translation }

        let isAtLeadingEdge = currentIndex == 0 && translation > 0
        let isAtTrailingEdge = currentIndex == data.count - 1 && translation < 0

        if isAtLeadingEdge || isAtTrailingEdge {
            return translation.withRubberbanding()
        }

        return translation
    }

    var dragGesture: some Gesture {
        // minimumDistance 0 claims the drag on touch-down so an enclosing pager yields instead of stealing the pan.
        DragGesture(minimumDistance: 0)
            .updating($translation) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                guard pageStep > 0 else { return }

                let rawOffset = (value.translation.width / pageStep * 1.5).rounded()

                if isEndless {
                    let offset = min(max(rawOffset, -1), 1)
                    let newIndex = currentIndex - Int(offset)
                    currentIndex = newIndex
                    scheduleEndlessBoundaryResetIfNeeded(for: newIndex)
                } else {
                    currentIndex = clamp(currentIndex - Int(rawOffset), min: 0, max: data.count - 1)
                }
            }
    }
}

// MARK: - Endless scrolling

private extension TangemCarousel {
    /// Items to display. In endless mode wraps with boundary duplicates `[last, ...data, first]`.
    var displayItems: [IndexedItem] {
        if isEndless {
            return extendedItems
        }

        return data.enumerated().map { IndexedItem(stableIndex: $0.offset, element: $0.element) }
    }

    var extendedItems: [IndexedItem] {
        guard let first = data.first, let last = data.last else { return [] }

        var result: [IndexedItem] = []
        result.reserveCapacity(data.count + 2)

        result.append(IndexedItem(stableIndex: -1, element: last))

        for (offset, element) in data.enumerated() {
            result.append(IndexedItem(stableIndex: offset, element: element))
        }

        result.append(IndexedItem(stableIndex: data.count, element: first))

        return result
    }

    /// The external index reported to consumers (always `0 ..< data.count`).
    var externalIndex: Int {
        guard !data.isEmpty else { return 0 }
        return (currentIndex % data.count + data.count) % data.count
    }

    func scheduleEndlessBoundaryResetIfNeeded(for index: Int) {
        let resetTarget: Int?

        if index < 0 {
            resetTarget = data.count - 1
        } else if index >= data.count {
            resetTarget = 0
        } else {
            resetTarget = nil
        }

        guard let target = resetTarget else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.05) {
            currentIndex = target
        }
    }
}

// MARK: - IndexedItem

private extension TangemCarousel {
    struct IndexedItem: Identifiable {
        let stableIndex: Int
        let element: Data.Element

        var id: Int { stableIndex }
    }
}

// MARK: - Setupable

extension TangemCarousel: Setupable {
    public func isEndless(_ endless: Bool) -> Self {
        map { $0.isEndless = endless }
    }

    public func interItemSpacing(_ spacing: CGFloat) -> Self {
        map { $0.interItemSpacing = spacing }
    }

    public func hidePagination(_ hide: Bool = true) -> Self {
        map { $0.hidePagination = hide }
    }

    public func paginationHasBackground(_ background: Bool) -> Self {
        map { $0.paginationHasBackground = background }
    }

    public func currentIndexHasChanged(_ changed: ((Int) -> Void)?) -> Self {
        map { $0.currentIndexHasChanged = changed }
    }

    public func onTranslationChanged(_ changed: ((CGFloat) -> Void)?) -> Self {
        map { $0.onTranslationChanged = changed }
    }
}
