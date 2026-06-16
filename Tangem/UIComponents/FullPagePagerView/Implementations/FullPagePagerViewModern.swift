//
//  FullPagePagerViewModern.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

/// iOS 17+ implementation using native ScrollView paging with `.scrollTargetBehavior(.paging)`.
/// Uses `.scrollPosition(id:)` for gesture tracking with phase-guarded initial positioning.
@available(iOS 17.0, *)
struct FullPagePagerViewModern<Data, Header, Body>: View
    where Data: RandomAccessCollection,
    Data.Element: Identifiable,
    Data.Index == Int,
    Header: View,
    Body: View {
    typealias HeaderFactory = (Data.Element) -> Header
    typealias BodyFactory = (Data.Element) -> Body

    // MARK: - Dependencies

    private let data: Data
    private let headerFactory: HeaderFactory
    private let bodyFactory: BodyFactory

    // MARK: - State

    @Binding private var selectedIndex: Int
    @Binding private var headerHeightRatio: CGFloat
    @State private var scrolledID: Data.Element.ID?
    @State private var scrollOffset: CGFloat = 0
    @State private var pageWidth: CGFloat = 0
    @StateObject private var elasticContainerModel: TangemElasticContainerModel
    @State private var scrollPhase: ScrollPhase = .awaitingLayout

    // MARK: - Configuration

    private let viewportHeight: CGFloat
    private var isScrollDisabled: Bool = false
    private var onPageChangeCallback: ((CardsInfoPageChangeReason) -> Void)?

    private let coordinateSpaceName = "pagerScrollView"
    private let positioningConvergenceThreshold: CGFloat = 0.25

    // MARK: - Initialization

    init(
        data: Data,
        selectedIndex: Binding<Int>,
        headerHeightRatio: Binding<CGFloat>,
        isScrollDisabled: Bool,
        viewportHeight: CGFloat,
        refreshScrollViewInteractor: RefreshScrollViewInteractor,
        onPageChangeCallback: ((CardsInfoPageChangeReason) -> Void)?,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder bodyFactory: @escaping BodyFactory
    ) {
        self.data = data
        _selectedIndex = selectedIndex
        _headerHeightRatio = headerHeightRatio
        self.isScrollDisabled = isScrollDisabled
        self.viewportHeight = viewportHeight
        _elasticContainerModel = StateObject(
            wrappedValue: TangemElasticContainerModel(scrollViewInteractor: refreshScrollViewInteractor)
        )
        self.onPageChangeCallback = onPageChangeCallback
        self.headerFactory = headerFactory
        self.bodyFactory = bodyFactory

        // Initialize to first element so .scrollPosition(id:) tracks from the start.
        // Phase guard prevents cascade during proxy.scrollTo() positioning.
        _scrolledID = State(initialValue: data.first?.id)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerContainer(pageWidth: pageWidth)

            bodyOffsetView(pageWidth: pageWidth)
                .frame(minHeight: viewportHeight)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            pageWidth = newWidth
        }
        .onReceive(elasticContainerModel.heightRatioPublisher) {
            headerHeightRatio = $0
        }
    }

    // MARK: - Header container

    private func headerContainer(pageWidth: CGFloat) -> some View {
        FullPagePagerHeaderContainer(
            elasticContainerModel: elasticContainerModel,
            content: headerScrollView(pageWidth: pageWidth)
        )
    }

    // MARK: - Header ScrollView

    private func headerScrollView(pageWidth: CGFloat) -> some View {
        ScrollViewReader { proxy in
            headerScrollContent(pageWidth: pageWidth)
                .coordinateSpace(name: coordinateSpaceName)
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $scrolledID)
                .scrollDisabled(isScrollDisabled)
                .fixedSize(horizontal: false, vertical: true)
                .onChange(of: scrolledID) { _, newID in
                    if case .positioning = scrollPhase { return }
                    updateSelectedIndex(from: newID)
                }
                .onChange(of: pageWidth) { _, newWidth in
                    handlePageWidthChange(newWidth, proxy: proxy)
                }
                .onChange(of: selectedIndex) { _, newIndex in
                    guard scrollPhase == .tracking else { return }
                    updateScrolledID(from: newIndex)
                }
        }
    }

    private func headerScrollContent(pageWidth: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(indexed: data.indexed()) { index, element in
                    headerPage(for: element, at: index, pageWidth: pageWidth)
                }
            }
            .scrollTargetLayout()
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.frame(in: .named(coordinateSpaceName)).minX
            } action: { offset in
                scrollOffset = -offset

                // Convergence check for initial positioning only
                if case .positioning(let target, let targetID) = scrollPhase, pageWidth > 0,
                   abs(-offset - target) < pageWidth * positioningConvergenceThreshold {
                    scrolledID = targetID
                    scrollPhase = .tracking
                }
            }
        }
    }

    private func headerPage(for element: Data.Element, at index: Int, pageWidth: CGFloat) -> some View {
        let pagePosition = CGFloat(index) * pageWidth
        let distance = abs(scrollOffset - pagePosition)
        let stationaryOpacity = pageWidth > 0 ? max(0, 1 - distance / pageWidth) : (index == 0 ? 1 : 0)

        return headerFactory(element)
            .environment(\.pagerStationaryOffset, scrollOffset - pagePosition)
            .environment(\.pagerStationaryOpacity, stationaryOpacity)
            .frame(width: pageWidth)
            .id(element.id)
    }

    private func handlePageWidthChange(_ newWidth: CGFloat, proxy: ScrollViewProxy) {
        guard newWidth > 0 else { return }

        switch scrollPhase {
        case .awaitingLayout, .positioning:
            let clampedIndex = data.isEmpty ? 0 : max(0, min(selectedIndex, data.count - 1))
            if clampedIndex != selectedIndex {
                selectedIndex = clampedIndex
            }

            let target = CGFloat(clampedIndex) * newWidth
            scrollOffset = target

            if clampedIndex == 0 {
                scrolledID = elementID(at: 0)
                scrollPhase = .tracking
            } else if let targetID = elementID(at: clampedIndex) {
                scrollPhase = .positioning(targetOffset: target, targetID: targetID)
                proxy.scrollTo(targetID, anchor: .leading)
            } else {
                scrolledID = data.first?.id
                scrollOffset = 0
                scrollPhase = .tracking
            }

        case .tracking:
            break
        }
    }

    // MARK: - Body with Offset

    private func bodyOffsetView(pageWidth: CGFloat) -> some View {
        FullPagePagerBodyContainer(
            data: data,
            scrollOffset: scrollOffset,
            pageWidth: pageWidth,
            contentFactory: bodyFactory
        )
    }

    // MARK: - Index Synchronization

    private func updateSelectedIndex(from id: Data.Element.ID?) {
        guard
            let id,
            let newIndex = indexForElement(withID: id),
            newIndex != selectedIndex
        else {
            return
        }

        selectedIndex = newIndex
        onPageChangeCallback?(.byGesture)
    }

    private func updateScrolledID(from index: Int) {
        guard let newID = elementID(at: index), newID != scrolledID else { return }

        scrolledID = newID
    }

    // MARK: - Helpers

    private func indexForElement(withID id: Data.Element.ID) -> Int? {
        guard let dataIndex = data.firstIndex(where: { $0.id == id }) else { return nil }

        return data.distance(from: data.startIndex, to: dataIndex)
    }

    private func elementID(at index: Int) -> Data.Element.ID? {
        guard index >= 0, index < data.count else { return nil }

        return data[data.index(data.startIndex, offsetBy: index)].id
    }
}

// MARK: - ScrollPhase

@available(iOS 17.0, *)
extension FullPagePagerViewModern {
    private enum ScrollPhase: Equatable {
        case awaitingLayout
        case positioning(targetOffset: CGFloat, targetID: Data.Element.ID)
        case tracking
    }
}
