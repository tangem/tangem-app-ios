//
//  CardsInfoPagerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardsInfoPagerView<
    Data, ID, Header, Body
>: View where Data: RandomAccessCollection, ID: Hashable, Header: View, Body: View, Data.Index == Int {
    typealias HeaderFactory = (_ element: Data.Element) -> Header
    typealias ContentFactory = (_ element: Data.Element) -> Body
    typealias OnPullToRefresh = OnRefresh

    private enum ProposedHeaderState {
        case collapsed
        case expanded
    }

    private enum PageSwitchMethod {
        case byGesture(DragGesture.Value)
        case programmatically(selectedIndex: Int)
    }

    // MARK: - Dependencies

    private let data: Data
    private let idProvider: KeyPath<(Data.Index, Data.Element), ID>
    private let headerFactory: HeaderFactory
    private let contentFactory: ContentFactory
    private let onPullToRefresh: OnPullToRefresh?

    // MARK: - Selected index

    @State private var selectedIndex: Int

    /// `External` here means 'driven from the outside' (by the consumer of this pager view).
    @Binding private var externalSelectedIndex: Int

    /// Contains previous value of the `selectedIndex` property.
    @State private var previouslySelectedIndex: Int

    /// The `content` part of the pager must be updated exactly in the middle of the active gesture/animation.
    /// Therefore, a separate property for a currently selected page index is used for the `content` part
    /// instead of the `selectedIndex` (`selectedIndex` is updated just after the drag gesture ends,
    /// whereas `content` part must be updated exactly in the middle of the current gesture/animation).
    @State private var contentSelectedIndex: Int

    @State private var scheduledContentSelectedIndexUpdate: DispatchWorkItem?

    /// Equals `true` if we a have valid next/previous index (relative to the currently selected index, `selectedIndex`)
    /// to select from the currently selected index, `false` otherwise.
    ///
    /// - Warning: This property has an undefined value if there is no active drag gesture.
    @State private var hasValidIndexToSelect = false

    private var selectedIndexLowerBound: Int { 0 }
    private var selectedIndexUpperBound: Int { data.count - 1 }

    // MARK: - Page switch progress

    /// Progress in 0...1 range, updated with animation.
    ///
    /// - Warning: Won't be reset back to 0 after a successful (non-cancelled) page switch, use with caution.
    @State private var pageSwitchProgress: CGFloat = .zero

    /// Progress in 0...1 range, updated without animation. Set at the end of the active drag gesture.
    ///
    /// - Warning: Won't be reset back to 0 after a successful (non-cancelled) page switch, use with caution.
    @State private var initialPageSwitchProgress: CGFloat = .zero

    /// Progress in 0...1 range, updated without animation. Set at the end of the active drag gesture.
    ///
    /// - Warning: Won't be reset back to 0 after a successful (non-cancelled) page switch, use with caution.
    @State private var finalPageSwitchProgress: CGFloat = .zero

    // MARK: - Horizontal scrolling

    @GestureState private var isDraggingHorizontally = false

    @GestureState private var currentHorizontalTranslation: CGFloat = .zero
    @State private var cumulativeHorizontalTranslation: CGFloat = .zero

    private var headerItemPeekHorizontalOffset: CGFloat {
        var offset = 0.0
        // Semantically, this is the same as `UICollectionViewFlowLayout.sectionInset` from UIKit
        offset += Constants.headerItemHorizontalOffset * CGFloat(selectedIndex + 1)
        // Semantically, this is the same as `UICollectionViewFlowLayout.minimumInteritemSpacing` from UIKit
        offset += Constants.headerInteritemSpacing * CGFloat(selectedIndex)
        return offset
    }

    private var animationsFactory: CardsInfoPagerAnimationFactory {
        return CardsInfoPagerAnimationFactory(
            hasValidIndexToSelect: hasValidIndexToSelect,
            currentPageSwitchProgress: pageSwitchProgress,
            minRemainingPageSwitchProgress: Constants.minRemainingPageSwitchProgress,
            pageSwitchAnimationDuration: pageSwitchAnimationDuration
        )
    }

    // MARK: - Vertical auto scrolling (collapsible/expandable header)

    @StateObject private var scrollDetector = ScrollDetector()

    @State private var proposedHeaderState: ProposedHeaderState = .expanded

    private let expandedHeaderScrollTargetIdentifier = UUID()
    private let collapsedHeaderScrollTargetIdentifier = UUID()
    private let scrollViewFrameCoordinateSpaceName = UUID()

    /// Different headers for different pages are expected to have the same height (otherwise visual glitches may occur).
    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Replace with native .safeAreaInset()")
    @State private var headerHeight: CGFloat = .zero
    @State private var verticalContentOffset: CGPoint = .zero
    @State private var contentSize: CGSize = .zero
    @State private var viewportSize: CGSize = .zero

    // MARK: - Configuration

    private var contentViewVerticalOffset: CGFloat = Constants.contentViewVerticalOffset
    private var pageSwitchThreshold: CGFloat = Constants.pageSwitchThreshold
    private var pageSwitchAnimationDuration: TimeInterval = Constants.pageSwitchAnimationDuration
    private var isHorizontalScrollDisabled = false

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            makeScrollView(with: proxy)
                .onAppear(perform: scrollDetector.startDetectingScroll)
                .onDisappear(perform: scrollDetector.stopDetectingScroll)
                .onAppear {
                    // `DispatchQueue.main.async` used here to allow publishing changes during view updates
                    DispatchQueue.main.async {
                        // Applying initial view's state based on the initial value of `selectedIndex`
                        cumulativeHorizontalTranslation = -CGFloat(selectedIndex) * proxy.size.width
                    }
                }
                .onChange(of: verticalContentOffset) { [oldValue = verticalContentOffset] newValue in
                    proposedHeaderState = oldValue.y > newValue.y ? .expanded : .collapsed
                    // Vertical scrolling may delay or even cancel horizontal scroll animations,
                    // which in turn may lead to desynchronization between `selectedIndex` and
                    // `contentSelectedIndex` properties.
                    // Therefore, we sync them forcefully when vertical scrolling starts.
                    synchronizeContentSelectedIndex()
                }
                .onChange(of: externalSelectedIndex) { newValue in
                    // Synchronizing external and private selected indices if needed
                    if newValue != selectedIndex {
                        switchPageProgrammatically(to: newValue, geometryProxy: proxy)
                    }
                }
                .onChange(of: data.count) { newValue in
                    // Handling edge cases when the very last page is selected and that page is being deleted
                    let clampedSelectedIndex = clamp(selectedIndex, min: selectedIndexLowerBound, max: newValue - 1)
                    if selectedIndex < clampedSelectedIndex || selectedIndex > clampedSelectedIndex {
                        switchPageProgrammatically(to: clampedSelectedIndex, geometryProxy: proxy)
                    }
                }
        }
        .modifier(
            CardsInfoPagerContentSwitchingModifier(
                progress: pageSwitchProgress,
                finalPageSwitchProgress: finalPageSwitchProgress,
                initialSelectedIndex: previouslySelectedIndex,
                finalSelectedIndex: selectedIndex
            )
        )
        .onAnimationCompleted(for: cumulativeHorizontalTranslation) {
            // Last resort workaround for rare edge cases of desynchronization between `selectedIndex`
            // and `contentSelectedIndex` properties if multiple page switching animations in
            // different directions are launched simultaneously.
            // The desynchronization is hard to reproduce and the reasons for such behavior are unknown.
            // This workaround guarantees that at the end of all animations, the values in `selectedIndex`
            // and `contentSelectedIndex` properties will be in sync.
            synchronizeContentSelectedIndex()
        }
        .onPreferenceChange(CardsInfoPagerContentSwitchingModifier.PreferenceKey.self) { newValue in
            scheduleContentSelectedIndexUpdateIfNeeded(toNewValue: newValue)
        }
        .onChange(of: selectedIndex) { newValue in
            // Synchronizing private and external selected indices
            externalSelectedIndex = newValue
        }
    }

    // MARK: - Initialization/Deinitialization

    init(
        data: Data,
        id idProvider: KeyPath<(Data.Index, Data.Element), ID>,
        selectedIndex: Binding<Int>,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder contentFactory: @escaping ContentFactory,
        onPullToRefresh: OnPullToRefresh? = nil
    ) {
        self.data = data
        self.idProvider = idProvider
        _selectedIndex = .init(initialValue: selectedIndex.wrappedValue)
        _previouslySelectedIndex = .init(initialValue: selectedIndex.wrappedValue)
        _contentSelectedIndex = .init(initialValue: selectedIndex.wrappedValue)
        _externalSelectedIndex = selectedIndex
        self.headerFactory = headerFactory
        self.contentFactory = contentFactory
        self.onPullToRefresh = onPullToRefresh
    }

    // MARK: - View factories

    @ViewBuilder
    private func makeHeader(with proxy: GeometryProxy) -> some View {
        // [REDACTED_TODO_COMMENT]
        HStack(spacing: Constants.headerInteritemSpacing) {
            ForEach(data.indexed(), id: idProvider) { index, element in
                headerFactory(element)
                    .frame(width: max(proxy.size.width - Constants.headerItemHorizontalOffset * 2.0, 0.0))
                    .readGeometry(\.size.height, bindTo: $headerHeight)
            }
        }
        // This offset translates the page based on swipe
        .offset(x: currentHorizontalTranslation)
        // This offset determines which page is shown
        .offset(x: cumulativeHorizontalTranslation)
        // This offset is responsible for the next/previous cell peek
        .offset(x: headerItemPeekHorizontalOffset)
        .infinityFrame(axis: .horizontal, alignment: .topLeading)
    }

    @ViewBuilder
    private func makeScrollView(with geometryProxy: GeometryProxy) -> some View {
        ScrollViewReader { scrollViewProxy in
            Group {
                if let onPullToRefresh = onPullToRefresh {
                    RefreshableScrollView(onRefresh: onPullToRefresh) {
                        makeContent(with: geometryProxy)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        makeContent(with: geometryProxy)
                    }
                }
            }
            .onChange(of: scrollDetector.isScrolling) { [oldValue = scrollDetector.isScrolling] newValue in
                if newValue != oldValue, !newValue {
                    performVerticalScrollIfNeeded(with: scrollViewProxy)
                }
            }
            .readGeometry(\.size, bindTo: $viewportSize)
            .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
        }
    }

    @ViewBuilder
    private func makeContent(with geometryProxy: GeometryProxy) -> some View {
        // ScrollView inserts default spacing between its content views.
        // Wrapping content into `VStack` prevents it.
        VStack(spacing: 0.0) {
            VStack(spacing: 0.0) {
                // This spacer acts as an auto scroll target when the header is expanded
                Spacer(minLength: Constants.headerVerticalPadding)
                    .fixedSize()
                    .id(expandedHeaderScrollTargetIdentifier)

                makeHeader(with: geometryProxy)
                    .gesture(
                        makeDragGesture(with: geometryProxy),
                        including: isHorizontalScrollDisabled ? .subviews : .all
                    )

                // This spacer is used to maintain `Constants.headerAdditionalSpacingHeight` (value
                // derived from mockups) spacing between the bottom edge of the navigation bar and
                // the top edge of the `content` part of a particular page when the header is collapsed
                Spacer(minLength: Constants.headerAdditionalSpacingHeight)
                    .fixedSize()

                // This spacer acts as an auto scroll target when the header is collapsed
                Spacer(minLength: Constants.headerVerticalPadding)
                    .fixedSize()
                    .id(collapsedHeaderScrollTargetIdentifier)

                if data.isEmpty {
                    EmptyView()
                } else {
                    contentFactory(data[clamp(contentSelectedIndex, min: selectedIndexLowerBound, max: selectedIndexUpperBound)])
                        .modifier(
                            CardsInfoPagerContentAnimationModifier(
                                progress: pageSwitchProgress,
                                verticalOffset: contentViewVerticalOffset,
                                hasValidIndexToSelect: hasValidIndexToSelect
                            )
                        )
                }
            }
            .readGeometry(
                \.size,
                throttleInterval: GeometryInfo.ThrottleInterval.aggressive,
                bindTo: $contentSize
            )
            .readContentOffset(
                inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName),
                throttleInterval: GeometryInfo.ThrottleInterval.aggressive,
                bindTo: $verticalContentOffset
            )

            CardsInfoPagerFlexibleFooterView(
                contentSize: contentSize,
                viewportSize: viewportSize,
                headerTopInset: Constants.headerVerticalPadding,
                headerHeight: headerHeight + Constants.headerAdditionalSpacingHeight
            )
        }
    }

    // MARK: - Gestures

    private func makeDragGesture(with proxy: GeometryProxy) -> some Gesture {
        DragGesture()
            .updating($currentHorizontalTranslation) { value, state, _ in
                state = valueWithRubberbandingIfNeeded(value.translation.width)
            }
            .updating($isDraggingHorizontally) { _, state, _ in
                state = true
            }
            .onChanged { value in
                let totalWidth = proxy.size.width
                let adjustedWidth = totalWidth
                    - Constants.headerItemHorizontalOffset
                    - Constants.headerInteritemSpacing

                pageSwitchProgress = abs(valueWithRubberbandingIfNeeded(value.translation.width) / adjustedWidth)

                // The `content` part of the page must be updated exactly in the middle of the
                // current gesture/animation, therefore `nextPageThreshold` equals 0.5 here
                contentSelectedIndex = nextIndexToSelectClamped(
                    translation: value.translation.width,
                    totalWidth: totalWidth,
                    nextPageThreshold: 0.5
                )

                // The presence/absence of the next index to select must be determined as soon as possible
                // when drag gesture starts, therefore `nextPageThreshold` is a relatively small value here
                let nextIndexToSelect = nextIndexToSelectFiltered(
                    translation: value.translation.width,
                    totalWidth: totalWidth,
                    nextPageThreshold: 1.0 / 100000.0 // 0.001%
                )
                hasValidIndexToSelect = nextIndexToSelect != nil && nextIndexToSelect != selectedIndex
            }
            .onEnded { value in
                switchPage(method: .byGesture(value), geometryProxy: proxy)
            }
    }

    // MARK: - Horizontal scrolling support

    /// Additional horizontal translation which takes into account horizontal offsets for next/previous cell peeking.
    private func additionalHorizontalTranslation(
        oldSelectedIndex: Int,
        newSelectedIndex: Int
    ) -> CGFloat {
        let multiplier: CGFloat
        if oldSelectedIndex < newSelectedIndex {
            // Successfull navigation to the next page (forward)
            multiplier = -1.0
        } else if oldSelectedIndex > newSelectedIndex {
            // Successfull navigation to the previous page (reverse)
            multiplier = 1.0
        } else {
            // Page switch threshold hasn't been exceeded, no page switching has been made
            multiplier = 0.0
        }

        return (Constants.headerItemHorizontalOffset + Constants.headerInteritemSpacing) * multiplier
    }

    private func valueWithRubberbandingIfNeeded<T>(_ value: T) -> T where T: BinaryFloatingPoint {
        return hasValidIndexToSelect ? value : value.withRubberbanding()
    }

    private func switchPage(method: PageSwitchMethod, geometryProxy proxy: GeometryProxy) {
        let totalWidth = proxy.size.width
        let newSelectedIndex = newSelectedIndex(from: method, totalWidth: totalWidth)
        let pageHasBeenSwitched = newSelectedIndex != selectedIndex
        let gestureProperties = gestureProperties(from: method)

        cumulativeHorizontalTranslation += valueWithRubberbandingIfNeeded(gestureProperties.translation.width)
        cumulativeHorizontalTranslation += additionalHorizontalTranslation(
            oldSelectedIndex: selectedIndex,
            newSelectedIndex: newSelectedIndex
        )

        if pageSwitchThreshold > 0.5, !pageHasBeenSwitched {
            // Fixes edge cases for page switch thresholds > 0.5 when page switch threshold
            // hasn't been exceeded: reverse animation should restore `contentSelectedIndex`
            // back to `selectedIndex` value exactly in the middle of the animation.
            // In order to achieve that we have to assign `previouslySelectedIndex` to a
            // different value, or SwiftUI's `onChange(of:perform:)` callback won't be triggered.
            previouslySelectedIndex = contentSelectedIndex
        } else {
            previouslySelectedIndex = selectedIndex
        }

        selectedIndex = newSelectedIndex
        initialPageSwitchProgress = pageSwitchProgress
        finalPageSwitchProgress = pageHasBeenSwitched ? 1.0 : 0.0

        let animation = animationsFactory.makeHorizontalScrollAnimation(
            totalWidth: totalWidth,
            dragGestureVelocity: gestureProperties.velocity,
            pageHasBeenSwitched: pageHasBeenSwitched
        )
        withAnimation(animation) {
            cumulativeHorizontalTranslation = -CGFloat(newSelectedIndex) * totalWidth
            pageSwitchProgress = finalPageSwitchProgress
        }
    }

    private func newSelectedIndex(from method: PageSwitchMethod, totalWidth: CGFloat) -> Int {
        switch method {
        case .byGesture(let gestureValue):
            return nextIndexToSelectClamped(
                translation: gestureValue.predictedEndTranslation.width,
                totalWidth: totalWidth,
                nextPageThreshold: pageSwitchThreshold
            )
        case .programmatically(let selectedIndex):
            return selectedIndex
        }
    }

    private func gestureProperties(from method: PageSwitchMethod) -> (translation: CGSize, velocity: CGSize) {
        switch method {
        case .byGesture(let gestureValue):
            return (gestureValue.translation, gestureValue.velocityCompat)
        case .programmatically:
            return (.zero, .zero)
        }
    }

    /// Convenience helper which resets view's state before performing page switch programmatically.
    private func switchPageProgrammatically(to selectedIndex: Int, geometryProxy proxy: GeometryProxy) {
        resetViewStateBeforeSwitchingPageProgrammatically()
        switchPage(method: .programmatically(selectedIndex: selectedIndex), geometryProxy: proxy)
    }

    private func resetViewStateBeforeSwitchingPageProgrammatically() {
        withTransaction(.withoutAnimations()) {
            pageSwitchProgress = 0.0
            hasValidIndexToSelect = true
        }
    }

    // MARK: - Vertical auto scrolling support (collapsible/expandable header)

    func performVerticalScrollIfNeeded(with scrollViewProxy: ScrollViewProxy) {
        let yOffset = verticalContentOffset.y - Constants.headerVerticalPadding

        guard 0.0 <= yOffset, yOffset < headerHeight else { return }

        let headerAutoScrollRatio: CGFloat
        if proposedHeaderState == .collapsed {
            headerAutoScrollRatio = Constants.headerAutoScrollThresholdRatio
        } else {
            headerAutoScrollRatio = 1.0 - Constants.headerAutoScrollThresholdRatio
        }

        withAnimation(.spring()) {
            if yOffset > headerHeight * headerAutoScrollRatio {
                scrollViewProxy.scrollTo(collapsedHeaderScrollTargetIdentifier, anchor: .top)
            } else {
                scrollViewProxy.scrollTo(expandedHeaderScrollTargetIdentifier, anchor: .top)
            }
        }
    }

    // MARK: - Selected index management

    private func nextIndexToSelectClamped(
        translation: CGFloat,
        totalWidth: CGFloat,
        nextPageThreshold: CGFloat
    ) -> Int {
        let nextIndex = nextIndexToSelect(
            translation: translation,
            totalWidth: totalWidth,
            nextPageThreshold: nextPageThreshold
        )
        return clamp(nextIndex, min: selectedIndexLowerBound, max: selectedIndexUpperBound)
    }

    private func nextIndexToSelectFiltered(
        translation: CGFloat,
        totalWidth: CGFloat,
        nextPageThreshold: CGFloat
    ) -> Int? {
        let nextIndex = nextIndexToSelect(
            translation: translation,
            totalWidth: totalWidth,
            nextPageThreshold: nextPageThreshold
        )
        return (selectedIndexLowerBound ... selectedIndexUpperBound) ~= nextIndex ? nextIndex : nil
    }

    private func nextIndexToSelect(
        translation: CGFloat,
        totalWidth: CGFloat,
        nextPageThreshold: CGFloat
    ) -> Int {
        let adjustedWidth = totalWidth
            - Constants.headerItemHorizontalOffset
            - Constants.headerInteritemSpacing
        let gestureProgress = translation / (adjustedWidth * nextPageThreshold * 2.0)
        let indexDiff = Int(gestureProgress.rounded())
        // The difference is clamped because we don't want to switch
        // by more than one page at a time in case of overscroll
        return selectedIndex - clamp(indexDiff, min: -1, max: 1)
    }

    /// Multiple simultaneous page switching animations may finish roughly at the same time,
    /// therefore we have to debounce multiple updates of the `contentSelectedIndex` property.
    private func scheduleContentSelectedIndexUpdateIfNeeded(toNewValue newValue: Int) {
        // `contentSelectedIndex` is being updated in `onChanged(_:)` callback
        // during an active horizontal drag gesture, nothing to do here
        guard !isDraggingHorizontally else { return }

        scheduledContentSelectedIndexUpdate?.cancel()

        let scheduledUpdate = DispatchWorkItem { contentSelectedIndex = newValue }
        scheduledContentSelectedIndexUpdate = scheduledUpdate
        DispatchQueue.main.async(execute: scheduledUpdate)
    }

    private func synchronizeContentSelectedIndex() {
        contentSelectedIndex = selectedIndex
    }
}

// MARK: - Convenience extensions

extension CardsInfoPagerView where Data.Element: Identifiable, Data.Element.ID == ID {
    init(
        data: Data,
        selectedIndex: Binding<Int>,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder contentFactory: @escaping ContentFactory,
        onPullToRefresh: OnPullToRefresh? = nil
    ) {
        self.init(
            data: data,
            id: \.1.id,
            selectedIndex: selectedIndex,
            headerFactory: headerFactory,
            contentFactory: contentFactory,
            onPullToRefresh: onPullToRefresh
        )
    }
}

// MARK: - Setupable protocol conformance

extension CardsInfoPagerView: Setupable {
    /// Maximum vertical offset for the `content` part of the page during
    /// gesture-driven or animation-driven page switch
    func contentViewVerticalOffset(_ offset: CGFloat) -> Self {
        map { $0.contentViewVerticalOffset = offset }
    }

    func pageSwitchThreshold(_ threshold: CGFloat) -> Self {
        map { $0.pageSwitchThreshold = threshold }
    }

    func pageSwitchAnimationDuration(_ value: CGFloat) -> Self {
        map { $0.pageSwitchAnimationDuration = value }
    }

    func horizontalScrollDisabled(_ disabled: Bool) -> Self {
        map { $0.isHorizontalScrollDisabled = disabled }
    }
}

// MARK: - Constants

private extension CardsInfoPagerView {
    private enum Constants {
        static var headerInteritemSpacing: CGFloat { 8.0 }
        static var headerItemHorizontalOffset: CGFloat { headerInteritemSpacing * 2.0 }
        static var headerVerticalPadding: CGFloat { 8.0 }
        static var headerAdditionalSpacingHeight: CGFloat { max(14.0 - Constants.headerVerticalPadding, 0.0) }
        static var headerAutoScrollThresholdRatio: CGFloat { 0.25 }
        static var contentViewVerticalOffset: CGFloat { 44.0 }
        static var pageSwitchThreshold: CGFloat { 0.5 }
        static var pageSwitchAnimationDuration: TimeInterval { 0.7 }
        static var minRemainingPageSwitchProgress: CGFloat { 1.0 / 3.0 }
    }
}

// MARK: - Previews

struct CardsInfoPagerView_Previews: PreviewProvider {
    private struct CardsInfoPagerPreview: View {
        var previewConfigs: [CardInfoPagePreviewConfig] {
            return [
                CardInfoPagePreviewConfig(initiallySelectedIndex: 0, hasPullToRefresh: true),
                CardInfoPagePreviewConfig(initiallySelectedIndex: 2, hasPullToRefresh: false),
            ]
        }

        var body: some View {
            ForEach(previewConfigs) { previewConfig in
                CardInfoPagePreviewContainerView(previewConfig: previewConfig)
            }
        }
    }

    static var previews: some View {
        CardsInfoPagerPreview()
    }
}
