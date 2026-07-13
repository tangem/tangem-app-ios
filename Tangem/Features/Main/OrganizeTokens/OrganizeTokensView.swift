//
//  OrganizeTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemFoundation
import TangemAccessibilityIdentifiers
import TangemAccounts

struct OrganizeTokensView: View {
    // MARK: - Model

    @ObservedObject private var viewModel: OrganizeTokensViewModel

    private let onCloseTap: (() -> Void)?

    @Environment(\.isAddAndOrganizeRedesignEnabled) private var isRedesign

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Content insets and overlay views

    @StateObject private var scrollState = OrganizeTokensScrollState(bottomInset: Constants.headerAdditionalBottomInset)

    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Replace with native `.safeAreaInset()` ([REDACTED_INFO])")
    @State private var scrollViewTopContentInset: CGFloat = 0.0

    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Replace with native `.safeAreaInset()` ([REDACTED_INFO])")
    @State private var scrollViewBottomContentInset: CGFloat = 0.0

    // MARK: - Drag and drop support

    @StateObject private var dragAndDropController: OrganizeTokensDragAndDropController

    @State private var dragAndDropSourceIndexPath: OrganizeTokensIndexPath?

    @State private var dragAndDropDestinationIndexPath: OrganizeTokensIndexPath?

    /// In a `scrollViewContentCoordinateSpaceName` coordinate space
    @State private var dragAndDropSourceItemFrame: CGRect?

    /// Stable identity, independent of changes in the underlying model (unlike index paths)
    @State private var dragAndDropSourceViewModelIdentifier: AnyHashable?

    @State private var dragGestureTranslation: CGSize?

    /// Semantically, this is the same as `UITableView.hasActiveDrag` from UIKit
    private var hasActiveDrag: Bool { dragAndDropSourceIndexPath != nil }

    // MARK: - Auto scrolling support

    /// Viewport insetted by `contentInset` (i.e. by `scrollViewTopContentInset` and `scrollViewBottomContentInset`)
    @State private var visibleViewportFrame: CGRect = .zero

    /// In a `.global` coordinate space
    @State private var draggedItemFrame: CGRect = .zero

    /// `Initial` here means 'at the beginning of the drag and drop gesture'.
    @State private var scrollViewInitialContentOffset: CGPoint = .zero

    /// Adopts changes in scroll view content offset (`scrollViewContentCoordinateSpaceName` coordinate space)
    /// to the drag gesture translation (`scrollViewFrameCoordinateSpaceName` coordinate space).
    /// Changes can be made by drag-and-drop auto scroll, for example.
    private var dragGestureTranslationFix: CGSize {
        return CGSize(
            width: 0.0,
            height: scrollState.contentOffset.y - scrollViewInitialContentOffset.y
        )
    }

    // MARK: - Layout

    @State private var tokenListWidth: CGFloat = .zero

    // MARK: - Colors

    private var backgroundColor: Color {
        if isRedesign {
            return Color.Tangem.Surface.level2
        }
        return .clear
    }

    private var cellBackgroundColor: Color {
        if isRedesign {
            return Color.Tangem.Surface.level3
        }
        return Colors.Background.action
    }

    // MARK: - Layout (redesign-aware)

    private var contentCornerRadius: CGFloat {
        isRedesign ? Constants.redesignContentCornerRadius : Constants.contentCornerRadius
    }

    private var contentHorizontalInset: CGFloat {
        isRedesign ? Constants.redesignContentHorizontalInset : Constants.contentHorizontalInset
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            tokenList

            topContent

            tokenListFooter
        }
        .background(backgroundColor.ignoresSafeArea(edges: .vertical))
        .toolbar { redesignedToolbarContent }
        .onWillAppear {
            dragAndDropController.dataSource = viewModel
            viewModel.onViewWillAppear()
        }
        .onAppear {
            scrollState.onViewAppear()
        }
    }

    @ToolbarContentBuilder
    private var redesignedToolbarContent: some ToolbarContent {
        // Standalone-sheet path (no custom `BottomSheetHeaderView`): host the sort menu in the native nav bar.
        if isRedesign, onCloseTap == nil, let headerViewModel = viewModel.headerViewModel {
            ToolbarItem(placement: .topBarTrailing) {
                OrganizeTokensSortMenuView(viewModel: headerViewModel, appliesGlassBackground: false)
            }
        }
    }

    // MARK: - Subviews

    private var tokenList: some View {
        ScrollViewReader { scrollProxy in
            tokenListScrollView(scrollProxy: scrollProxy)
        }
        .overlay(tokenListDraggableOverlay, alignment: .top)
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { tokenListWidth in
            self.tokenListWidth = tokenListWidth
        }
        .coordinateSpace(name: CoordinateSpaceName.ScrollView.frame)
        .onReceive(scrollState.contentOffsetSubject) { newValue in
            dragAndDropController.contentOffsetSubject.send(newValue)
            updateDragAndDropDestinationIndexPath(using: dragGestureTranslation)
        }
        .onChange(of: dragAndDropDestinationIndexPath) { [oldValue = dragAndDropDestinationIndexPath] newValue in
            guard let oldValue = oldValue, let newValue = newValue else { return }

            dragAndDropController.onItemsMove()
            viewModel.move(from: oldValue, to: newValue)
        }
        .onChange(of: hasActiveDrag) { newValue in
            if newValue {
                scrollState.onDragStart()
            } else {
                scrollState.onDragEnd()
                dragAndDropController.stopAutoScrolling()
                dragAndDropDestinationIndexPath = nil
                dragAndDropSourceItemFrame = nil
            }
        }
        .onChange(of: dragGestureTranslation) { newValue in
            updateDragAndDropDestinationIndexPath(using: newValue)
        }
    }

    private var tokenListContent: some View {
        let parametersProvider = OrganizeTokensListCornerRadiusParametersProvider(
            sections: viewModel.sections,
            cornerRadius: contentCornerRadius
        )

        return ForEach(indexed: viewModel.sections.indexed()) { outerSectionIndex, outerSectionViewModel in
            Section(
                content: {
                    ForEach(indexed: outerSectionViewModel.items.indexed()) { innerSectionIndex, innerSectionViewModel in
                        Section(
                            content: {
                                ForEach(indexed: innerSectionViewModel.items.indexed()) { itemIndex, itemViewModel in
                                    let indexPath = OrganizeTokensIndexPath(
                                        outerSection: outerSectionIndex,
                                        innerSection: innerSectionIndex,
                                        item: itemIndex
                                    )
                                    let identifier = itemViewModel.id
                                    let isDragged = identifier.toAnyHashable() == dragAndDropSourceViewModelIdentifier

                                    makeCell(
                                        viewModel: itemViewModel,
                                        atIndexPath: indexPath,
                                        parametersProvider: parametersProvider
                                    )
                                    .hidden(isDragged)
                                    .accessibilityHidden(isDragged)
                                    .readGeometry(
                                        \.frame,
                                        inCoordinateSpace: .named(CoordinateSpaceName.ScrollView.content)
                                    ) { frame in
                                        if !isDragged {
                                            dragAndDropController.saveFrame(frame, forItemAt: indexPath)
                                        }
                                    }
                                    .id(identifier)
                                }
                            },
                            header: {
                                let indexPath = OrganizeTokensIndexPath(
                                    outerSection: outerSectionIndex,
                                    innerSection: innerSectionIndex,
                                    item: viewModel.sectionHeaderItemIndex
                                )
                                let identifier = innerSectionViewModel.id
                                let isDragged = identifier == dragAndDropSourceViewModelIdentifier
                                let isOuterSectionInvisible = outerSectionViewModel.model.style == .invisible

                                makeInnerSection(
                                    from: innerSectionViewModel,
                                    atIndexPath: indexPath,
                                    parametersProvider: parametersProvider
                                )
                                .hidden(isDragged)
                                .accessibilityHidden(isDragged)
                                .readGeometry(
                                    \.frame,
                                    inCoordinateSpace: .named(CoordinateSpaceName.ScrollView.content)
                                ) { frame in
                                    if !isDragged {
                                        dragAndDropController.saveFrame(frame, forItemAt: indexPath)
                                    }
                                }
                                .id(identifier)
                                .padding(.top, innerSectionIndex != 0 && isOuterSectionInvisible ? Constants.interSectionSpacing : 0.0)
                            }
                        )
                    }
                },
                header: {
                    makeOuterSection(
                        from: outerSectionViewModel,
                        atIndex: outerSectionIndex,
                        parametersProvider: parametersProvider
                    )
                    .padding(.top, outerSectionIndex != 0 ? Constants.interSectionSpacing : 0.0)
                }
            )
        }
    }

    private var topContent: some View {
        VStack(spacing: 0) {
            tokenListTitle
            tokenListHeader
        }
        // Full width so the `.bar` band paints behind the system nav-bar title when `topContent` is otherwise empty.
        .frame(maxWidth: .infinity)
        .background(.bar.hidden(scrollState.isNavigationBarBackgroundHidden))
        .padding(.bottom, Constants.headerAdditionalBottomInset)
        .readGeometry(\.size.height, bindTo: $scrollViewTopContentInset)
        .infinityFrame(alignment: .top)
    }

    @ViewBuilder
    private var tokenListTitle: some View {
        if let onCloseTap {
            BottomSheetHeaderView(
                title: Localization.organizeTokensTitle,
                trailing: { headerTrailing(onCloseTap: onCloseTap) }
            )
            .padding(.top, 4)
            .padding(.horizontal, contentHorizontalInset)
        }
    }

    @ViewBuilder
    private func headerTrailing(onCloseTap: @escaping () -> Void) -> some View {
        if isRedesign, let headerViewModel = viewModel.headerViewModel {
            OrganizeTokensSortMenuView(viewModel: headerViewModel, appliesGlassBackground: true)
        } else {
            NavigationBarButton.close(action: onCloseTap)
        }
    }

    @ViewBuilder
    private var tokenListHeader: some View {
        // [REDACTED_INFO]: legacy inline sort/group header — hidden under `.redesign` because controls moved into the navbar dropdown
        if !isRedesign, let headerViewModel = viewModel.headerViewModel {
            OrganizeTokensListHeader(
                viewModel: headerViewModel,
                horizontalInset: contentHorizontalInset,
                bottomInset: Constants.headerBottomInset
            )
        }
    }

    private var tokenListFooter: some View {
        Group {
            if isRedesign {
                OrganizeTokensListFooterRedesigned(
                    actionsHandler: viewModel,
                    isTokenListFooterGradientHidden: scrollState.isTokenListFooterGradientHidden,
                    contentInsets: footerContentInsets
                )
            } else {
                OrganizeTokensListFooter(
                    actionsHandler: viewModel,
                    isTokenListFooterGradientHidden: scrollState.isTokenListFooterGradientHidden,
                    cornerRadius: contentCornerRadius,
                    contentInsets: footerContentInsets
                )
            }
        }
        .animation(.linear(duration: 0.1), value: scrollState.isTokenListFooterGradientHidden)
        .readGeometry(inCoordinateSpace: .global) { geometryInfo in
            scrollState.tokenListFooterFrameMinYSubject.send(geometryInfo.frame.minY + Constants.contentVerticalInset)
            $scrollViewBottomContentInset.wrappedValue = geometryInfo.size.height
        }
        .infinityFrame(alignment: .bottom)
    }

    private var footerContentInsets: EdgeInsets {
        EdgeInsets(
            top: Constants.contentVerticalInset,
            leading: contentHorizontalInset,
            bottom: 0.0,
            trailing: contentHorizontalInset
        )
    }

    init(
        viewModel: OrganizeTokensViewModel,
        onCloseTap: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onCloseTap = onCloseTap
        _dragAndDropController = .init(
            wrappedValue: OrganizeTokensDragAndDropController(
                autoScrollFrequency: Constants.autoScrollFrequency,
                destinationItemSelectionThresholdRatio: Constants.dragAndDropDestinationItemSelectionThresholdRatio,
                topEdgeAdditionalAutoScrollTargets: [Identifiers.ScrollView.topContentInsetSpacer],
                bottomEdgeAdditionalAutoScrollTargets: [Identifiers.ScrollView.bottomContentInsetSpacer]
            )
        )
    }

    // MARK: - Drag and drop support

    private func newDragAndDropSessionPrecondition() {
        // The following assertions verify that the drag-and-drop related @State variables
        // have been properly reset at the end of the previous drag-and-drop session
        assert(dragAndDropDestinationIndexPath == nil)
        assert(dragAndDropSourceItemFrame == nil)
        assert(dragAndDropSourceViewModelIdentifier == nil)
    }

    private func updateDragAndDropDestinationIndexPath(using dragGestureTranslation: CGSize?) {
        guard
            let dragGestureTranslation = dragGestureTranslation,
            let sourceIndexPath = dragAndDropSourceIndexPath,
            let currentDestinationIndexPath = dragAndDropDestinationIndexPath,
            let updatedDestinationIndexPath = dragAndDropController.updatedDestinationIndexPath(
                source: sourceIndexPath,
                currentDestination: currentDestinationIndexPath,
                translationValue: dragGestureTranslation + dragGestureTranslationFix
            )
        else {
            return
        }

        dragAndDropDestinationIndexPath = updatedDestinationIndexPath
    }

    private func resetGestureState() {
        scrollViewInitialContentOffset = .zero
        dragAndDropSourceIndexPath = nil
        dragGestureTranslation = nil
    }

    // MARK: - Auto scrolling support

    private func scrollAnchor() -> UnitPoint? {
        switch dragAndDropController.autoScrollStatus {
        case .active(.top):
            return .top
        case .active(.bottom):
            return .bottom
        case .inactive:
            return nil
        }
    }

    private func changeAutoScrollStatusIfNeeded(draggedItemFrame: CGRect) {
        guard
            hasActiveDrag,
            visibleViewportFrame.canBeRendered,
            draggedItemFrame.canBeRendered
        else {
            return
        }

        let intersection = visibleViewportFrame.intersection(draggedItemFrame)
        if intersection.height < min(visibleViewportFrame.height, draggedItemFrame.height) {
            if draggedItemFrame.minY + Constants.autoScrollTriggerHeightDiff < visibleViewportFrame.minY {
                dragAndDropController.startAutoScrolling(direction: .top)
            } else if draggedItemFrame.maxY - Constants.autoScrollTriggerHeightDiff > visibleViewportFrame.maxY {
                dragAndDropController.startAutoScrolling(direction: .bottom)
            }
        } else if !intersection.isNull {
            dragAndDropController.stopAutoScrolling()
        }
    }

    // MARK: - View factories

    @ViewBuilder
    private func makeCell(
        viewModel: OrganizeTokensListItemViewModel,
        atIndexPath indexPath: OrganizeTokensIndexPath,
        parametersProvider: OrganizeTokensListCornerRadiusParametersProvider
    ) -> some View {
        Group {
            if isRedesign {
                OrganizeTokensListItemViewRedesigned(viewModel: viewModel)
            } else {
                OrganizeTokensListItemView(viewModel: viewModel)
            }
        }
        .accessibilityIdentifier(
            OrganizeTokensAccessibilityIdentifiers.tokenAtPosition(
                name: viewModel.name,
                outerSection: indexPath.outerSection,
                innerSection: indexPath.innerSection,
                item: indexPath.item
            )
        )
        .background(cellBackgroundColor)
        .cornerRadius(
            parametersProvider.cornerRadius(forItemAt: indexPath),
            corners: parametersProvider.rectCorners(forItemAt: indexPath)
        )
    }

    @ViewBuilder
    private func makeInnerSection(
        from section: OrganizeTokensListInnerSection,
        atIndexPath indexPath: OrganizeTokensIndexPath,
        parametersProvider: OrganizeTokensListCornerRadiusParametersProvider
    ) -> some View {
        Group {
            switch section.model.style {
            case .invisible:
                EmptyView()
            case .fixed(let title):
                makeInnerSectionView(title: title, identifier: section.model.id, isDraggable: false)
            case .draggable(let title):
                makeInnerSectionView(title: title, identifier: section.model.id, isDraggable: true)
            }
        }
        .background(cellBackgroundColor)
        .cornerRadius(
            parametersProvider.cornerRadius(forInnerSectionAt: indexPath),
            corners: parametersProvider.rectCorners(forInnerSectionAt: indexPath)
        )
    }

    @ViewBuilder
    private func makeInnerSectionView(title: String, identifier: AnyHashable, isDraggable: Bool) -> some View {
        if isRedesign {
            OrganizeTokensListInnerSectionViewRedesigned(title: title, identifier: identifier, isDraggable: isDraggable)
        } else {
            OrganizeTokensListInnerSectionView(title: title, identifier: identifier, isDraggable: isDraggable)
        }
    }

    @ViewBuilder
    private func makeOuterSection(
        from section: OrganizeTokensListOuterSection,
        atIndex sectionIndex: Int,
        parametersProvider: OrganizeTokensListCornerRadiusParametersProvider
    ) -> some View {
        Group {
            switch section.model.style {
            case .invisible:
                EmptyView()
            case .default(let title, let iconData):
                if isRedesign {
                    OrganizeTokensListOuterSectionViewRedesigned(
                        title: title,
                        iconData: iconData,
                        outerSectionIndex: sectionIndex,
                        accountId: section.model.id
                    )
                } else {
                    OrganizeTokensListOuterSectionView(
                        title: title,
                        iconData: iconData,
                        outerSectionIndex: sectionIndex,
                        accountId: section.model.id
                    )
                }
            }
        }
        .background(cellBackgroundColor)
        .cornerRadius(
            parametersProvider.cornerRadius(forOuterSectionAtIndex: sectionIndex),
            corners: parametersProvider.rectCorners(forOuterSectionAtIndex: sectionIndex)
        )
    }

    private func makeDragAndDropGestureOverlayView() -> some View {
        DragAndDropGestureView(
            minimumPressDuration: Constants.dragAndDropGestureDuration,
            allowableMovement: Constants.dragAndDropGestureAllowableMovement,
            gesturePredicate: OrganizeTokensDragAndDropGesturePredicate(),
            contextProvider: OrganizeTokensDragAndDropGestureContextProvider(),
            onLongPressChanged: { isRecognized, context in
                if isRecognized {
                    guard
                        let sourceViewModelIdentifier = context,
                        let sourceIndexPath = viewModel.indexPath(for: sourceViewModelIdentifier)
                    else {
                        return
                    }

                    // One-time assignment before the value of drag gesture changes for the first time
                    scrollViewInitialContentOffset = scrollState.contentOffset

                    // Set initial state for `dragAndDropSourceIndexPath` after successfully ended long press gesture
                    dragAndDropSourceIndexPath = sourceIndexPath

                    // Set initial state for `dragAndDropDestinationIndexPath` after successfully ended long press gesture
                    dragAndDropDestinationIndexPath = sourceIndexPath
                    dragAndDropSourceItemFrame = dragAndDropController.frame(forItemAt: sourceIndexPath)
                    dragAndDropSourceViewModelIdentifier = sourceViewModelIdentifier

                    dragAndDropController.onDragStart()
                    viewModel.onDragStart(at: sourceIndexPath)
                } else {
                    newDragAndDropSessionPrecondition()
                    dragAndDropController.onDragPrepare()
                }
            },
            onDragChanged: { translation, _ in
                dragGestureTranslation = translation
            },
            onEnded: { _ in
                resetGestureState()
            },
            onCancel: { _ in
                resetGestureState()
            }
        )
    }

    @ViewBuilder
    private func makeDraggableComponent(width: CGFloat) -> some View {
        if let dragAndDropSourceIndexPath = dragAndDropSourceIndexPath,
           let dragAndDropSourceItemFrame = dragAndDropSourceItemFrame,
           let dragAndDropSourceViewModelIdentifier = dragAndDropSourceViewModelIdentifier,
           let dragAndDropDestinationIndexPath = dragAndDropDestinationIndexPath {
            let parametersProvider = OrganizeTokensListCornerRadiusParametersProvider(
                sections: viewModel.sections,
                cornerRadius: Constants.draggableViewCornerRadius
            )

            makeDraggableView(
                width: width,
                indexPath: dragAndDropDestinationIndexPath,
                itemFrame: dragAndDropSourceItemFrame
            ) {
                if let section = viewModel.section(for: dragAndDropSourceViewModelIdentifier) {
                    makeInnerSection(
                        from: section,
                        atIndexPath: dragAndDropSourceIndexPath,
                        parametersProvider: parametersProvider
                    )
                } else if let itemViewModel = viewModel.itemViewModel(for: dragAndDropSourceViewModelIdentifier) {
                    makeCell(
                        viewModel: itemViewModel,
                        atIndexPath: dragAndDropSourceIndexPath,
                        parametersProvider: parametersProvider
                    )
                }
            }
        }
    }

    private func makeDraggableView<Content>(
        width: CGFloat,
        indexPath: OrganizeTokensIndexPath,
        itemFrame: CGRect,
        @ViewBuilder content: () -> Content
    ) -> some View where Content: View {
        let scaleTransitionValue = width / (width * Constants.draggableViewScale)
        let offsetTransitionRatio = 1.0 - scaleTransitionValue

        let destinationItemFrame = dragAndDropController.frame(forItemAt: indexPath) ?? .zero
        let baseOffsetTransitionValue = itemFrame.origin.y + (dragGestureTranslation?.height ?? .zero)
        let totalOffsetTransitionValue = baseOffsetTransitionValue - scrollViewInitialContentOffset.y

        let additionalOffsetRemovalTransitionValue = destinationItemFrame.minY
            - baseOffsetTransitionValue
            - dragGestureTranslationFix.height

        return content()
            .frame(width: width)
            .readGeometry(\.frame, inCoordinateSpace: .global, bindTo: $draggedItemFrame)
            .scaleEffect(Constants.draggableViewScale)
            .offset(y: totalOffsetTransitionValue)
            .transition(
                .scale(scale: scaleTransitionValue)
                    .combined(with: .offset(y: totalOffsetTransitionValue * offsetTransitionRatio))
                    .combined(
                        with: .asymmetric(
                            insertion: .identity,
                            removal: .offset(y: additionalOffsetRemovalTransitionValue)
                        )
                    )
                    .combined(
                        with: .cornerRadius(
                            insertionOffset: totalOffsetTransitionValue,
                            removalOffset: totalOffsetTransitionValue + additionalOffsetRemovalTransitionValue
                        )
                    )
                    .combined(with: .shadow(colorScheme: colorScheme))
                    .combined(with: .onViewRemoval { dragAndDropSourceViewModelIdentifier = nil })
            )
            .onDisappear {
                // Perform required clean-up when the view removal animation finishes
                //
                // `dragAndDropSourceViewModelIdentifier` nullified here one more time,
                // in case if `AnyTransition.onViewRemoval` is unexpectedly cancelled
                dragAndDropSourceViewModelIdentifier = nil
                viewModel.onDragAnimationCompletion()
            }
    }
}

// MARK: - Convenience extensions

private extension AnyTransition {
    static func shadow(colorScheme: ColorScheme) -> AnyTransition {
        let color: Color
        let radius: CGFloat
        let offset: CGPoint

        switch colorScheme {
        case .dark:
            color = Color.black.opacity(0.26)
            radius = 20.0
            offset = CGPoint(x: 0.0, y: 2.0)
        case .light:
            fallthrough
        @unknown default:
            color = Color.black.opacity(0.08)
            radius = 14.0
            offset = CGPoint(x: 0.0, y: 8.0)
        }

        return .modifier(
            active: ShadowAnimatableModifier(progress: 0.0, color: color, radius: radius, offset: offset),
            identity: ShadowAnimatableModifier(progress: 1.0, color: color, radius: radius, offset: offset)
        )
    }

    static func cornerRadius(insertionOffset: CGFloat, removalOffset: CGFloat) -> AnyTransition {
        return .modifier(
            active: CornerRadiusAnimatableModifier(
                progress: 0.0,
                cornerRadius: 0.0,
                cornerRadiusStyle: .continuous
            ) { clipShape in
                clipShape
                    .scale(1.0)
                    .offset(y: removalOffset)
            },
            identity: CornerRadiusAnimatableModifier(
                progress: 1.0,
                cornerRadius: OrganizeTokensView.Constants.draggableViewCornerRadius,
                cornerRadiusStyle: .continuous
            ) { clipShape in
                clipShape
                    .scale(OrganizeTokensView.Constants.draggableViewScale)
                    .offset(y: insertionOffset)
            }
        )
    }

    static func onViewRemoval(perform action: @escaping () -> Void) -> AnyTransition {
        let dummyViewInsertionProgressObserver = AnimationProgressObserverModifier(observedValue: 1.0) {}
        let viewRemovalProgressObserver = AnimationProgressObserverModifier(
            observedValue: 0.0,
            targetValue: OrganizeTokensView.Constants.dropAnimationProgressThresholdForViewRemoval,
            valueComparator: <=,
            action: action
        )

        return .modifier(
            active: viewRemovalProgressObserver,
            identity: dummyViewInsertionProgressObserver
        )
    }
}

// MARK: - Constants

private extension OrganizeTokensView {
    enum Constants {
        static let contentCornerRadius = 14.0
        static let redesignContentCornerRadius: CGFloat = 20
        static let interSectionSpacing = 8.0
        static let headerBottomInset = 10.0
        static var headerAdditionalBottomInset: CGFloat { contentVerticalInset - headerBottomInset }
        static let contentVerticalInset = 14.0
        static let contentHorizontalInset = 16.0
        static let redesignContentHorizontalInset: CGFloat = 12
        static let dragAndDropGestureDuration = 0.15
        static let dragAndDropGestureAllowableMovement = 5.0
        static let dragLiftAnimationDuration = 0.2
        static let dropAnimationProgressThresholdForViewRemoval = 0.1
        static let dragAndDropDestinationItemSelectionThresholdRatio = 0.5
        static let draggableViewScale = 1.035
        static let draggableViewCornerRadius = 7.0
        static let autoScrollFrequency = 0.2
        static let autoScrollTriggerHeightDiff = 10.0
    }

    enum Identifiers {
        enum ScrollView {
            private static let prefix = "OrganizeTokensView.Identifiers.ScrollView."

            static let topContentInsetSpacer = prefix + "topContentInsetSpacer"
            static let bottomContentInsetSpacer = prefix + "bottomContentInsetSpacer"
        }
    }

    enum CoordinateSpaceName {
        enum ScrollView {
            private static let prefix = "OrganizeTokensView.CoordinateSpaceName.ScrollView."

            static let content = prefix + "content"
            static let frame = prefix + "frame"
        }
    }
}

// MARK: - Token list subviews

private extension OrganizeTokensView {
    var tokenListScrollContent: some View {
        VStack(spacing: 0.0) {
            LazyVStack(spacing: 0.0) {
                Spacer(minLength: scrollViewTopContentInset)
                    .fixedSize()
                    .id(Identifiers.ScrollView.topContentInsetSpacer)

                tokenListContent
            }
            .animation(.spring(), value: viewModel.sections)
            .padding(.horizontal, contentHorizontalInset)
            .coordinateSpace(name: CoordinateSpaceName.ScrollView.content)
            .readGeometry(
                \.frame.maxY,
                inCoordinateSpace: .global,
                bindTo: scrollState.tokenListContentFrameMaxYSubject.asWriteOnlyBinding(.zero)
            )
            .readContentOffset(
                inCoordinateSpace: .named(CoordinateSpaceName.ScrollView.frame),
                bindTo: scrollState.contentOffsetSubject.asWriteOnlyBinding(.zero)
            )
            .overlay(makeDragAndDropGestureOverlayView())

            Spacer(minLength: scrollViewBottomContentInset)
                .fixedSize()
                .id(Identifiers.ScrollView.bottomContentInsetSpacer)
        }
    }

    func tokenListScrollView(scrollProxy: ScrollViewProxy) -> some View {
        ScrollView(showsIndicators: false) {
            tokenListScrollContent
        }
        .accessibilityIdentifier(OrganizeTokensAccessibilityIdentifiers.tokensList)
        .readGeometry(\.frame, inCoordinateSpace: .global) { newValue in
            dragAndDropController.viewportSizeSubject.send(newValue.size)
            visibleViewportFrame = newValue
                .divided(atDistance: scrollViewTopContentInset, from: .minYEdge)
                .remainder
                .divided(atDistance: scrollViewBottomContentInset, from: .maxYEdge)
                .remainder
        }
        .onChange(of: draggedItemFrame) { newValue in
            changeAutoScrollStatusIfNeeded(draggedItemFrame: newValue)
        }
        .onReceive(dragAndDropController.autoScrollTargetPublisher) { newValue in
            withAnimation(.linear(duration: Constants.autoScrollFrequency)) {
                scrollProxy.scrollTo(newValue, anchor: scrollAnchor())
            }
        }
    }

    var tokenListDraggableOverlay: some View {
        makeDraggableComponent(width: max(0, tokenListWidth - contentHorizontalInset * 2.0))
            .animation(.linear(duration: Constants.dragLiftAnimationDuration), value: hasActiveDrag)
    }
}
