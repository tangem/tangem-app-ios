//
//  FullPagePagerViewLegacy.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

/// iOS 16 implementation using UIKit UIScrollView with `isPagingEnabled` via UIViewRepresentable.
/// Provides native paging behavior and memory efficiency through windowed rendering.
struct FullPagePagerViewLegacy<Data, Header, Body>: View
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
    /// Tracks the current scroll offset for smooth body synchronization during gestures
    @State private var scrollOffset: CGFloat = 0
    /// Measured header height reported by UIKit, used to constrain header frame
    @State private var headerHeight: CGFloat = 0

    // MARK: - Configuration

    private var isScrollDisabled: Bool = false
    private var onPageChangeCallback: ((CardsInfoPageChangeReason) -> Void)?

    // MARK: - Initialization

    init(
        data: Data,
        selectedIndex: Binding<Int>,
        isScrollDisabled: Bool,
        onPageChangeCallback: ((CardsInfoPageChangeReason) -> Void)?,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder bodyFactory: @escaping BodyFactory
    ) {
        self.data = data
        _selectedIndex = selectedIndex
        self.isScrollDisabled = isScrollDisabled
        self.onPageChangeCallback = onPageChangeCallback
        self.headerFactory = headerFactory
        self.bodyFactory = bodyFactory
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let pageWidth = geometry.size.width

            VStack(spacing: 0) {
                headerContainer(pageWidth: pageWidth)
                bodyContainer(pageWidth: pageWidth)
            }
            .onAppear {
                scrollOffset = CGFloat(selectedIndex) * pageWidth
            }
            .onChange(of: selectedIndex) { newValue in
                scrollOffset = CGFloat(newValue) * pageWidth
            }
        }
    }

    // MARK: - View Builders

    private func headerContainer(pageWidth: CGFloat) -> some View {
        PagingScrollView(
            pageCount: data.count,
            currentPage: $selectedIndex,
            pageWidth: pageWidth,
            isScrollDisabled: isScrollDisabled,
            onScrollOffsetChange: { offset in
                scrollOffset = offset
            },
            onPageChange: { _ in
                onPageChangeCallback?(.byGesture)
            },
            onHeightChange: { height in
                headerHeight = height
            }
        ) {
            ForEach(indexed: data.indexed()) { index, element in
                let pagePosition = CGFloat(index) * pageWidth
                let distance = abs(scrollOffset - pagePosition)
                let stationaryOpacity = max(0, 1 - distance / pageWidth)

                headerFactory(element)
                    .environment(\.pagerStationaryOffset, scrollOffset - pagePosition)
                    .environment(\.pagerStationaryOpacity, stationaryOpacity)
                    .frame(width: pageWidth)
            }
        }
        .frame(height: headerHeight > 0 ? headerHeight : nil)
    }

    private func bodyContainer(pageWidth: CGFloat) -> some View {
        FullPagePagerBodyContainer(
            data: data,
            scrollOffset: scrollOffset,
            pageWidth: pageWidth,
            contentFactory: bodyFactory
        )
    }
}

// MARK: - UIKit Paging ScrollView

/// UIKit-based horizontal paging scroll view for **iOS 16 only**.
///
/// We chose UIKit's `UIScrollView` with `isPagingEnabled` instead of pure SwiftUI workarounds because:
///
/// 1. **No native paging in iOS 16**: `.scrollTargetBehavior(.paging)` requires iOS 17+
/// 2. **Native physics**: UIKit provides battle-tested paging with proper rubber-band effect and deceleration.
///    Pure SwiftUI requires manual `DragGesture` + snapping which never feels quite right.
/// 3. **Gesture handling**: Manual snapping conflicts with nested gestures (e.g., vertical scroll in body).
///    UIKit's gesture system handles this correctly out of the box.
/// 4. **Reliable scroll tracking**: `UIScrollViewDelegate` provides precise offset callbacks.
///    SwiftUI's `ScrollViewReader` lacks real-time position tracking in iOS 16.
///
/// iOS 17+ uses native SwiftUI paging via `FullPagePagerViewModern`.
private struct PagingScrollView<Content: View>: UIViewRepresentable {
    let pageCount: Int
    @Binding var currentPage: Int
    let pageWidth: CGFloat
    let isScrollDisabled: Bool
    let onScrollOffsetChange: (CGFloat) -> Void
    let onPageChange: (Int) -> Void
    let onHeightChange: (CGFloat) -> Void
    let content: () -> Content

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = context.coordinator
        scrollView.isScrollEnabled = !isScrollDisabled

        let hostingController = UIHostingController(rootView: HStack(spacing: 0) { content() })
        hostingController.view.backgroundColor = .clear
        scrollView.addSubview(hostingController.view)

        context.coordinator.hostingController = hostingController

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.parent = self
        scrollView.isScrollEnabled = !isScrollDisabled

        guard let hostingController = context.coordinator.hostingController else { return }

        updateContent(hostingController: hostingController)
        updateLayout(scrollView: scrollView, hostingController: hostingController, context: context)
        syncScrollPosition(scrollView: scrollView, isDragging: context.coordinator.isDragging)
    }

    private func updateContent(hostingController: UIHostingController<HStack<Content>>) {
        hostingController.rootView = HStack(spacing: 0) { content() }
    }

    private func updateLayout(scrollView: UIScrollView, hostingController: UIHostingController<HStack<Content>>, context: Context) {
        let totalWidth = pageWidth * CGFloat(pageCount)
        let targetSize = CGSize(width: totalWidth, height: UIView.layoutFittingCompressedSize.height)
        let fittedSize = hostingController.sizeThatFits(in: targetSize)

        let contentHeight = fittedSize.height
        scrollView.contentSize = CGSize(width: totalWidth, height: contentHeight)
        hostingController.view.frame = CGRect(origin: .zero, size: scrollView.contentSize)

        if abs(contentHeight - context.coordinator.lastReportedHeight) > 0.5 {
            context.coordinator.lastReportedHeight = contentHeight
            DispatchQueue.main.async {
                onHeightChange(contentHeight)
            }
        }
    }

    private func syncScrollPosition(scrollView: UIScrollView, isDragging: Bool) {
        guard !isDragging, pageWidth > 0 else { return }

        let targetOffset = CGFloat(currentPage) * pageWidth
        let needsSync = abs(scrollView.contentOffset.x - targetOffset) > 1

        if needsSync {
            scrollView.setContentOffset(CGPoint(x: targetOffset, y: 0), animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: PagingScrollView
        var hostingController: UIHostingController<HStack<Content>>?
        var isDragging = false
        var lastReportedHeight: CGFloat = 0

        init(_ parent: PagingScrollView) {
            self.parent = parent
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isDragging = true
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // Report offset changes during scrolling for body synchronization
            parent.onScrollOffsetChange(scrollView.contentOffset.x)
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isDragging = false
            updateCurrentPage(scrollView)
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                isDragging = false
                updateCurrentPage(scrollView)
            }
        }

        func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            isDragging = false
            updateCurrentPage(scrollView)
        }

        private func updateCurrentPage(_ scrollView: UIScrollView) {
            guard parent.pageWidth > 0 else { return }

            let page = Int(round(scrollView.contentOffset.x / parent.pageWidth))
            let clampedPage = max(0, min(page, parent.pageCount - 1))

            if clampedPage != parent.currentPage {
                parent.currentPage = clampedPage
                parent.onPageChange(clampedPage)
            }
        }
    }
}
