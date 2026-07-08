//
//  TangemCarousel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit
import TangemFoundation
import TangemUIUtils

public struct TangemCarousel<Data, Content>: View
    where Data: RandomAccessCollection, Data.Element: Hashable, Data.Element: Identifiable, Content: View {
    private let data: Data
    private let content: (Data.Element) -> Content

    private let animationDuration: TimeInterval = 0.3

    private var isEndless: Bool = false
    private var interItemSpacing: CGFloat = 0
    private var paginationSpacing: CGFloat = SizeUnit.x4.value
    private var paginationVerticalPadding: CGFloat = 0
    private var hidePagination: Bool = false
    private var paginationHasBackground: Bool = false
    private var currentIndexHasChanged: ((Int) -> Void)?
    private var onTranslationChanged: ((CGFloat) -> Void)?

    @State private var currentIndex: Int
    @State private var translation: CGFloat = 0
    @State private var isSettling = false
    @State private var containerWidth: CGFloat = 0
    @State private var dragEndGeneration = 0
    @State private var endlessDisplayIndexOverride: Int?

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
        VStack(spacing: paginationSpacing) {
            pages

            if !hidePagination, data.count > 1 {
                TangemPagination(
                    totalPages: data.count,
                    currentIndex: externalIndex,
                    hasBackground: paginationHasBackground
                )
                .padding(.vertical, paginationVerticalPadding)
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
            endlessDisplayIndexOverride = nil
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
        } else if let currentElement {
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
        HStack(alignment: .top, spacing: interItemSpacing) {
            ForEach(displayItems, id: \.id) { item in
                content(item.element)
                    .frame(width: containerWidth)
            }
        }
        .frame(width: containerWidth, alignment: .leading)
        .offset(x: offsetX)
        .animation(isSettling ? .easeOut(duration: animationDuration) : nil, value: offsetX)
        .frame(width: containerWidth, alignment: .center)
        .background {
            if data.count > 1 {
                HorizontalPanAttacher(
                    onChanged: { handleDragChange(translation: $0) },
                    onEnded: { handleDragEnd(translation: $0, predictedTranslation: $1) }
                )
            }
        }
    }
}

// MARK: - Gesture

private extension TangemCarousel {
    var pageStep: CGFloat {
        containerWidth + interItemSpacing
    }

    func displayIndex(for index: Int) -> Int {
        isEndless ? index + 1 : index
    }

    var visualDisplayIndex: Int {
        if isEndless, let endlessDisplayIndexOverride {
            return endlessDisplayIndexOverride
        }

        return displayIndex(for: currentIndex)
    }

    var offsetX: CGFloat {
        -CGFloat(visualDisplayIndex) * pageStep + effectiveTranslation
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

    func handleDragChange(translation: CGFloat) {
        if isEndless {
            if isSettling || endlessDisplayIndexOverride != nil {
                dragEndGeneration += 1
            }

            currentIndex = normalizedEndlessIndex(currentIndex)
            endlessDisplayIndexOverride = nil
        }

        isSettling = false
        self.translation = translation
        onTranslationChanged?(translation)
    }

    func handleDragEnd(translation endTranslation: CGFloat, predictedTranslation: CGFloat) {
        onTranslationChanged?(0)

        guard pageStep > 0 else {
            translation = 0
            return
        }

        if isEndless {
            currentIndex = normalizedEndlessIndex(currentIndex)
            endlessDisplayIndexOverride = nil
        }

        let shouldFlip = abs(endTranslation) > pageStep * Constants.minDragPageFractionToFlip
            || abs(predictedTranslation) > pageStep * Constants.minFlickPageFractionToFlip
        let offset = shouldFlip ? (endTranslation > 0 ? 1 : -1) : 0

        isSettling = true
        translation = 0

        dragEndGeneration += 1
        let generation = dragEndGeneration

        if isEndless {
            let landingIndex = currentIndex - offset
            currentIndex = normalizedEndlessIndex(landingIndex)
            endlessDisplayIndexOverride = endlessOverrideDisplayIndex(for: landingIndex)
        } else {
            currentIndex = clamp(currentIndex - offset, min: 0, max: data.count - 1)
        }

        let settleDelay: TimeInterval
        if isEndless {
            settleDelay = animationDuration + Constants.endlessBoundaryResetDelayAfterAnimation
        } else {
            settleDelay = animationDuration
        }

        Task { @MainActor in
            try? await ContinuousClock().sleep(for: .seconds(settleDelay))
            guard generation == dragEndGeneration else { return }
            isSettling = false
            endlessDisplayIndexOverride = nil
        }
    }
}

// MARK: - Endless scrolling

private extension TangemCarousel {
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

    var externalIndex: Int {
        normalizedEndlessIndex(currentIndex)
    }

    func endlessOverrideDisplayIndex(for index: Int) -> Int? {
        if index < 0 {
            return 0
        }

        if index >= data.count {
            return data.count + 1
        }

        return nil
    }

    func normalizedEndlessIndex(_ index: Int) -> Int {
        guard !data.isEmpty else { return 0 }
        return (index % data.count + data.count) % data.count
    }
}

// MARK: - Constants

private enum Constants {
    static let minDragPageFractionToFlip: CGFloat = 1.0 / 3.0
    static let minFlickPageFractionToFlip: CGFloat = 1.0 / 2.0
    static let flickProjectionInterval: CGFloat = 0.25
    static let endlessBoundaryResetDelayAfterAnimation: TimeInterval = 0.05
    static let axisVelocityDeadZone: CGFloat = 1
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

    public func paginationSpacing(_ spacing: CGFloat) -> Self {
        map { $0.paginationSpacing = spacing }
    }

    public func paginationVerticalPadding(_ padding: CGFloat) -> Self {
        map { $0.paginationVerticalPadding = padding }
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

// MARK: - HorizontalPanAttacher

private struct HorizontalPanAttacher: UIViewRepresentable {
    let onChanged: (CGFloat) -> Void
    let onEnded: (_ translation: CGFloat, _ predictedTranslation: CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChanged: onChanged, onEnded: onEnded)
    }

    func makeUIView(context: Context) -> OnWindowAttachView {
        let view = OnWindowAttachView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.onAttachToWindow = { [weak coordinator = context.coordinator] in coordinator?.attachIfNeeded(from: $0) }
        return view
    }

    func updateUIView(_ uiView: OnWindowAttachView, context: Context) {
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
    }

    static func dismantleUIView(_ uiView: OnWindowAttachView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onChanged: (CGFloat) -> Void
        var onEnded: (CGFloat, CGFloat) -> Void
        private weak var marker: UIView?
        private var pan: UIPanGestureRecognizer?

        private var isAttached: Bool {
            pan?.view != nil
        }

        init(onChanged: @escaping (CGFloat) -> Void, onEnded: @escaping (CGFloat, CGFloat) -> Void) {
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        func attachIfNeeded(from marker: UIView) {
            guard !isAttached, marker.window != nil else { return }
            self.marker = marker

            let ancestors = marker.ancestors
            let scrollViews = ancestors.compactMap { $0 as? UIScrollView }
            guard let target = scrollViews.first ?? ancestors.last else { return }

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            pan.delegate = self
            pan.cancelsTouchesInView = true
            pan.delaysTouchesBegan = false
            pan.delaysTouchesEnded = false
            self.pan = pan

            target.addGestureRecognizer(pan)
            for scrollView in scrollViews {
                scrollView.panGestureRecognizer.require(toFail: pan)
            }
        }

        func detach() {
            if let pan {
                pan.removeTarget(self, action: nil)
                pan.view?.removeGestureRecognizer(pan)
            }
            pan = nil
            marker = nil
        }

        @objc
        private func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)

            switch gesture.state {
            case .began, .changed:
                onChanged(translation.x)
            case .ended:
                let velocity = gesture.velocity(in: gesture.view)
                let predicted = translation.x + velocity.x * Constants.flickProjectionInterval
                onEnded(translation.x, predicted)
            case .cancelled, .failed:
                onEnded(0, 0)
            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
            guard let pan = gesture as? UIPanGestureRecognizer, let marker else { return false }

            let location = pan.location(in: marker)
            guard marker.bounds.contains(location) else { return false }

            let velocity = pan.velocity(in: pan.view)
            let translation = pan.translation(in: pan.view)
            let dx = abs(velocity.x) > Constants.axisVelocityDeadZone ? abs(velocity.x) : abs(translation.x)
            let dy = abs(velocity.y) > Constants.axisVelocityDeadZone ? abs(velocity.y) : abs(translation.y)
            return dx > dy
        }
    }
}
