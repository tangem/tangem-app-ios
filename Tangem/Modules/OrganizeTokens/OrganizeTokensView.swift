//
//  OrganizeTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensView: View {
    @ObservedObject private var viewModel: OrganizeTokensViewModel

    @Environment(\.displayScale) private var displayScale

    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Use native 'safeAreaInset()' instead")
    @State private var scrollViewBottomContentInset = 0.0

    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Use native 'safeAreaInset()' instead")
    @State private var scrollViewTopContentInset = 0.0

    @State private var tokenListFooterFrameMinY: CGFloat = 0.0
    @State private var tokenListContentFrameMaxY: CGFloat = 0.0
    @State private var isTokenListFooterGradientHidden = true

    @GestureState
    private var hasActiveDrag = false

    @StateObject
    private var dragAndDropController = OrganizeTokensDragAndDropController(
        cellSelectionThresholdHeight: 68.0 // [REDACTED_TODO_COMMENT]
    )

    @State
    private var dragAndDropSourceCellSnapshot: UIImage?

    private var dragAndDropSourceCellFrame: CGRect? { dragAndDropController.frame(forItemAtIndexPath: dragAndDropSourceIndexPath) }

    @State
    private var dragAndDropInitialIndexPath: IndexPath?

    @GestureState
    private var dragAndDropSourceIndexPath: IndexPath?

    @GestureState
    private var dragAndDropDestinationIndexPath: IndexPath?

    @GestureState
    private var dragGestureTranslation: CGSize = .zero

    @GestureState
    private var dragGestureLocation: CGPoint?

    // Semantically, this is the same as `UIScrollView.frameLayoutGuide` from UIKit
    private let scrollViewFrameCoordinateSpaceName = UUID()

    // Semantically, this is the same as `UIScrollView.contentLayoutGuide` from UIKit
    private let scrollViewContentCoordinateSpaceName = UUID()

    init(viewModel: OrganizeTokensViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ZStack {
                Group {
                    tokenList

                    tokenListHeader
                }
                .padding(.horizontal, Constants.contentHorizontalInset)

                tokenListFooter
            }
            .background(
                Colors.Background
                    .secondary
                    .ignoresSafeArea(edges: [.vertical])
            )
            .navigationTitle(Localization.organizeTokensTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var tokenList: some View {
        GeometryReader { geometryProxy in
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    Spacer(minLength: scrollViewTopContentInset)

                    LazyVStack(spacing: 0.0) {
                        let parametersProvider = OrganizeTokensListCornerRadiusParametersProvider(
                            sections: viewModel.sections,
                            cornerRadius: Constants.cornerRadius
                        )

                        ForEach(indexed: viewModel.sections.indexed()) { sectionIndex, sectionViewModel in
                            Section(
                                content: {
                                    ForEach(indexed: sectionViewModel.items.indexed()) { itemIndex, itemViewModel in
                                        let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                                        makeCell(viewModel: itemViewModel, indexPath: indexPath, parametersProvider: parametersProvider)
                                            .opacity(indexPath == dragAndDropDestinationIndexPath ? 0.05 : 1.0)
                                            .id(itemViewModel.id)
                                            .background(
                                                // [REDACTED_TODO_COMMENT]
                                                GeometryReader { proxy -> Color in
                                                    let frame = proxy.frame(in: .named(scrollViewContentCoordinateSpaceName))
                                                    dragAndDropController.saveFrame(frame, forItemAtIndexPath: indexPath)
                                                    return Color.clear
                                                }
                                            )
                                    }
                                },
                                header: {
                                    Group {
                                        switch sectionViewModel.style {
                                        case .invisible:
                                            EmptyView()
                                        case .fixed(let title):
                                            OrganizeTokensListSectionView(title: title, isDraggable: false)
                                        case .draggable(let title):
                                            OrganizeTokensListSectionView(title: title, isDraggable: true)
                                        }
                                    }
                                    .background(Colors.Background.primary)
                                    .cornerRadius(
                                        parametersProvider.cornerRadius(forSectionAtIndex: sectionIndex),
                                        corners: parametersProvider.rectCorners(forSectionAtIndex: sectionIndex)
                                    )
                                }
                            )
                        }
                    }
                    .readGeometry(to: $tokenListContentFrameMaxY, transform: \.frame.maxY)
                    .coordinateSpace(name: scrollViewContentCoordinateSpaceName)
                    .overlay(makeDragAndDropSourceCellSnapshot(), alignment: .top)
                    .onTouchesBegan { location in
                        dragAndDropInitialIndexPath = dragAndDropController.indexPath(forLocation: location)
                    }

                    Spacer(minLength: scrollViewBottomContentInset)
                }
                .onChange(of: dragGestureLocation) { value in
                    guard let value, var dragAndDropSourceCellFrame else { return }

                    dragAndDropSourceCellFrame.origin.y += dragGestureTranslation.height

                    guard let cirrIndexPath = dragAndDropController.indexPath(forLocation: dragAndDropSourceCellFrame.origin) else { return }

                    let locationY = value.y
                    let diff = 68.0 // [REDACTED_TODO_COMMENT]

                    // [REDACTED_TODO_COMMENT]
                    if locationY < diff {
                        if cirrIndexPath.item > 0 {
                            let newSection = cirrIndexPath.section
                            let newItem = cirrIndexPath.item - 1
                            let prevCellId = viewModel.sections[newSection].items[newItem].id
                            withAnimation {
                                scrollProxy.scrollTo(prevCellId)
                            }
                        } else if cirrIndexPath.section > 0 {
                            let newSection = cirrIndexPath.section - 1
                            let newItem = viewModel.sections[newSection].items.count - 1
                            let prevCellId = viewModel.sections[newSection].items[newItem].id
                            withAnimation {
                                scrollProxy.scrollTo(prevCellId)
                            }
                        }
                    } else if locationY > geometryProxy.size.height - diff {
                        if cirrIndexPath.item < viewModel.sections[cirrIndexPath.section].items.count - 1 {
                            let newSection = cirrIndexPath.section
                            let newItem = cirrIndexPath.item + 1
                            let nextCellId = viewModel.sections[newSection].items[newItem].id
                            withAnimation {
                                scrollProxy.scrollTo(nextCellId)
                            }
                        } else if cirrIndexPath.section < viewModel.sections.count - 1 {
                            let newSection = cirrIndexPath.section + 1
                            let newItem = 0
                            let nextCellId = viewModel.sections[newSection].items[newItem].id
                            withAnimation {
                                scrollProxy.scrollTo(nextCellId)
                            }
                        }
                    }
                }
            }
        }
        .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
        .onTapGesture {} // allows scroll to work, see https://developer.apple.com/forums/thread/127277 for details
        .gesture(
            makeDragAndDropGesture()
        )
        .onChange(of: dragAndDropSourceIndexPath) { value in
            guard
                let value,
                let frame = dragAndDropController.frame(forItemAtIndexPath: value)
            else {
                dragAndDropSourceCellSnapshot = nil
                return
            }

            let parametersProvider = OrganizeTokensListCornerRadiusParametersProvider(
                sections: viewModel.sections,
                cornerRadius: Constants.cornerRadius
            )
            dragAndDropSourceCellSnapshot = makeCell(
                viewModel: viewModel.sections[value.section].items[value.item],
                indexPath: value,
                parametersProvider: parametersProvider
            )
            .frame(size: frame.size)
            .scaleEffect(x: 1.1, y: 1.1)
            .snapshot(displayScale: displayScale)
        }
        .onChange(of: dragAndDropDestinationIndexPath) { [oldValue = dragAndDropDestinationIndexPath] newValue in
            guard let oldValue, let newValue else { return }

            dragAndDropController.onItemsMove()

            viewModel.move(
                itemInSection: newValue.section,
                fromSourceIndex: oldValue.item,
                toDestinationIndex: newValue.item
            )
        }
        .onChange(of: tokenListContentFrameMaxY) { newValue in
            withAnimation {
                isTokenListFooterGradientHidden = newValue < tokenListFooterFrameMinY
            }
        }
    }

    private var tokenListHeader: some View {
        OrganizeTokensHeaderView(viewModel: viewModel.headerViewModel)
            .readGeometry(transform: \.size.height) { height in
                scrollViewTopContentInset = height + Constants.overlayViewAdditionalVerticalInset + 8.0
            }
            .padding(.top, 8.0)
            .infinityFrame(alignment: .top)
    }

    private var tokenListFooter: some View {
        HStack(spacing: 8.0) {
            Group {
                MainButton(
                    title: Localization.commonCancel,
                    style: .secondary,
                    action: viewModel.onCancelButtonTap
                )

                MainButton(
                    title: Localization.commonApply,
                    style: .primary,
                    action: viewModel.onApplyButtonTap
                )
            }
            .background(
                Colors.Background
                    .primary
                    .cornerRadiusContinuous(Constants.cornerRadius)
            )
        }
        .padding(.horizontal, Constants.contentHorizontalInset)
        .background(tokenListFooterGradientOverlay)
        .readGeometry { geometryInfo in
            tokenListFooterFrameMinY = geometryInfo.frame.minY
            scrollViewBottomContentInset = geometryInfo.size.height + Constants.overlayViewAdditionalVerticalInset
        }
        .infinityFrame(alignment: .bottom)
    }

    private var tokenListFooterGradientOverlay: some View {
        LinearGradient(
            colors: [Colors.Background.fadeStart, Colors.Background.fadeEnd],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
        .hidden(isTokenListFooterGradientHidden)
        .ignoresSafeArea()
        .frame(height: 100.0)
        .infinityFrame(alignment: .bottom)
    }

    @ViewBuilder
    private func makeCell(
        viewModel: OrganizeTokensListItemViewModel,
        indexPath: IndexPath,
        parametersProvider: OrganizeTokensListCornerRadiusParametersProvider
    ) -> some View {
        OrganizeTokensListItemView(viewModel: viewModel)
            .background(Colors.Background.primary)
            .cornerRadius(
                parametersProvider.cornerRadius(forItemAtIndexPath: indexPath),
                corners: parametersProvider.rectCorners(forItemAtIndexPath: indexPath)
            )
            .padding(.horizontal, 16.0)
    }

    private func makeDragAndDropGesture() -> some Gesture {
        LongPressGesture(minimumDuration: 1.0)
            .sequenced(before: DragGesture(coordinateSpace: .named(scrollViewFrameCoordinateSpaceName)))
            .updating($dragGestureLocation) { value, state, _ in
                switch value {
                case .first:
                    break
                case .second(_, let dragGestureValue):
                    if let dragGestureValue {
                        state = dragGestureValue.location
                    }
                }
            }
            .updating($dragGestureTranslation) { value, state, _ in
                switch value {
                case .first(let isLongPressGestureInitiated):
                    if isLongPressGestureInitiated {
                        // Long press gesture successfully recognized
                        dragAndDropController.onDragPrepare()
                    }
                case .second(let isLongPressGestureEnded, let dragGestureValue):
                    if let dragGestureValue {
                        state = dragGestureValue.translation
                    } else if isLongPressGestureEnded {
                        // Long press gesture successfully ended
                        dragAndDropController.onDragStart()
                    }
                }
            }
            .updating($hasActiveDrag) { value, state, _ in
                switch value {
                case .first:
                    break
                case .second(let isLongPressGestureEnded, _):
                    state = isLongPressGestureEnded
                }
            }
            .updating($dragAndDropSourceIndexPath) { value, state, _ in
                switch value {
                case .first:
                    break
                case .second(let isLongPressGestureEnded, let dragGestureValue):
                    if isLongPressGestureEnded, dragGestureValue == nil {
                        // Long press gesture successfully ended
                        state = dragAndDropInitialIndexPath
                    }
                }
            }
            .updating($dragAndDropDestinationIndexPath) { value, state, _ in
                switch value {
                case .first:
                    break
                case .second(let isLongPressGestureEnded, let dragGestureValue):
                    guard isLongPressGestureEnded else { return }

                    if let dragGestureValue, let sourceIndexPath = dragAndDropSourceIndexPath, let currentDestinationIndexPath = state {
                        if let updatedDestinationIndexPath = dragAndDropController.updatedDestinationIndexPathForDragAndDrop(
                            sourceIndexPath: sourceIndexPath,
                            currentDestinationIndexPath: currentDestinationIndexPath,
                            translationValue: dragGestureValue.translation
                        ) {
                            state = updatedDestinationIndexPath
                        }
                    } else {
                        // Initial state after successfully ended long press gesture
                        state = dragAndDropInitialIndexPath
                    }
                }
            }
    }

    @ViewBuilder
    private func makeDragAndDropSourceCellSnapshot() -> some View {
        if let dragAndDropSourceCellSnapshot {
            Image(uiImage: dragAndDropSourceCellSnapshot)
                .transition(.opacity)
                .cornerRadius(14.0)
                .offset(y: dragAndDropSourceCellFrame?.origin.y ?? 0.0)
                .offset(y: dragGestureTranslation.height)
        }
    }
}

// MARK: - Constants

private extension OrganizeTokensView {
    enum Constants {
        static let cornerRadius = 14.0
        static let overlayViewAdditionalVerticalInset = 10.0
        static let contentHorizontalInset = 16.0
    }
}

// MARK: - Previews

struct OrganizeTokensView_Preview: PreviewProvider {
    private static let previewProvider = OrganizeTokensPreviewProvider()

    static var previews: some View {
        let viewModels = [
            previewProvider.multipleSections(),
            previewProvider.singleMediumSection(),
            previewProvider.singleSmallSection(),
        ]

        Group {
            ForEach(viewModels.indexed(), id: \.0.self) { index, sections in
                OrganizeTokensView(
                    viewModel: .init(
                        coordinator: OrganizeTokensCoordinator(),
                        sections: sections
                    )
                )
            }
        }
        .background(Colors.Background.primary)
        .previewLayout(.sizeThatFits)
        .background(Colors.Background.secondary.ignoresSafeArea())
    }
}
