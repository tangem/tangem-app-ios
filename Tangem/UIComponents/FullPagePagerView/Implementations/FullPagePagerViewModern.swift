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
/// Provides true lazy loading via LazyHStack inside ScrollView.
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
    @State private var scrolledID: Data.Element.ID?
    @State private var scrollOffset: CGFloat = 0
    @State private var pageWidth: CGFloat = 0

    // MARK: - Configuration

    private let viewportHeight: CGFloat
    private var isScrollDisabled: Bool = false
    private var onPageChangeCallback: ((CardsInfoPageChangeReason) -> Void)?

    private let coordinateSpaceName = "pagerScrollView"

    // MARK: - Initialization

    init(
        data: Data,
        selectedIndex: Binding<Int>,
        isScrollDisabled: Bool,
        viewportHeight: CGFloat,
        onPageChangeCallback: ((CardsInfoPageChangeReason) -> Void)?,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder bodyFactory: @escaping BodyFactory
    ) {
        self.data = data
        _selectedIndex = selectedIndex
        self.isScrollDisabled = isScrollDisabled
        self.viewportHeight = viewportHeight
        self.onPageChangeCallback = onPageChangeCallback
        self.headerFactory = headerFactory
        self.bodyFactory = bodyFactory

        let index = selectedIndex.wrappedValue
        let initialID = data.indices.contains(index) ? data[index].id : data.first?.id
        _scrolledID = State(initialValue: initialID)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerScrollView(pageWidth: pageWidth)

            bodyOffsetView(pageWidth: pageWidth)
                .frame(minHeight: viewportHeight)
        }
        .readGeometry(\.size.width) { pageWidth = $0 }
        .onChange(of: selectedIndex) { _, newIndex in
            updateScrolledID(from: newIndex)
        }
    }

    // MARK: - Header ScrollView

    private func headerScrollView(pageWidth: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(indexed: data.indexed()) { index, element in
                    let pagePosition = CGFloat(index) * pageWidth
                    let distance = abs(scrollOffset - pagePosition)
                    let stationaryOpacity = max(0, 1 - distance / pageWidth)

                    headerFactory(element)
                        .environment(\.pagerStationaryOffset, scrollOffset - pagePosition)
                        .environment(\.pagerStationaryOpacity, stationaryOpacity)
                        .frame(width: pageWidth)
                        .id(element.id)
                }
            }
            .scrollTargetLayout()
            .readGeometry(\.frame.minX, inCoordinateSpace: .named(coordinateSpaceName)) { offset in
                scrollOffset = -offset
            }
        }
        .coordinateSpace(name: coordinateSpaceName)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrolledID)
        .scrollDisabled(isScrollDisabled)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: scrolledID) { _, newID in
            updateSelectedIndex(from: newID)
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
