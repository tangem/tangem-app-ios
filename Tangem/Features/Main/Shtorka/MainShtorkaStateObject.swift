//
//  MainShtorkaStateObject.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemUI

final class MainShtorkaStateObject: ObservableObject {
    @Injected(\.mainBottomSheetUIManager) private var bottomSheetUIManager: MainBottomSheetUIManager

    @Published var isPresented = false
    @Published var size: ShtorkaSize = .collapsed

    @Published private(set) var isContentCollapsed = true

    @Published private var feedDetents = ShtorkaDetents()
    @Published private var isNavigationActive = false
    @Published private var isSearchActive = false
    @Published private var collapsedBottomInset: CGFloat = .zero

    var mainContentBottomInset: CGFloat {
        isPresented ? collapsedBottomInset : .zero
    }

    var detents: ShtorkaDetents {
        guard isNavigationActive || isSearchActive else { return feedDetents }

        // The detent set deduplicates collapsed, and its reverse mapping still resolves to collapsed.
        return ShtorkaDetents(collapsed: feedDetents.collapsed, medium: feedDetents.collapsed, full: feedDetents.full)
    }

    var expansionProgressPublisher: AnyPublisher<CGFloat, Never> {
        heights.expansionProgressPublisher
    }

    private let heights = FeedDetentHeights()
    private var bag = Set<AnyCancellable>()

    init() {
        heights.detentsPublisher.assign(to: &$feedDetents)
        heights.$isContentCollapsed.assign(to: &$isContentCollapsed)
        heights.$collapsedBottomInset.assign(to: &$collapsedBottomInset)

        bind()
    }

    func collapse() {
        size = .collapsed
    }

    func expand() {
        size = .full
    }

    func setNavigationActive(_ isActive: Bool) {
        if isActive {
            expand()
        }
        isNavigationActive = isActive
    }

    func setSearchActive(_ isActive: Bool) {
        if isActive {
            expand()
        }
        isSearchActive = isActive
    }

    // MARK: - Detent heights

    func report(searchBar height: CGFloat) {
        heights.report(searchBar: height)
    }

    func report(widgets height: CGFloat) {
        heights.report(widgets: height)
    }

    func report(tabChips height: CGFloat) {
        heights.report(tabChips: height)
    }

    func report(safeArea insets: EdgeInsets) {
        heights.report(safeArea: insets)
    }

    func report(window height: CGFloat) {
        heights.report(window: height)
    }

    func report(sheetHeight height: CGFloat) {
        heights.report(sheetHeight: height)
    }
}

// MARK: - Visibility

private extension MainShtorkaStateObject {
    func bind() {
        bottomSheetUIManager
            .isShownPublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { stateObject, isShown in
                isShown ? stateObject.present() : stateObject.hide()
            }
            .store(in: &bag)

        $size
            .map { $0 != .collapsed }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { stateObject, isExpanded in
                stateObject.bottomSheetUIManager.setExpanded(isExpanded)
            }
            .store(in: &bag)
    }

    func present() {
        guard !isPresented else {
            return
        }

        withAnimation {
            isPresented = true
        }
    }

    func hide() {
        guard isPresented else {
            return
        }

        // Instant on purpose: the sheet is normally taken away by a push transition, and an animated dismissal
        // would argue with it.
        withTransaction(.withoutAnimations()) {
            isPresented = false
            collapse()
        }

        heights.report(sheetHeight: .zero)
    }
}

// MARK: - FeedDetentReporting

extension MainShtorkaStateObject: FeedDetentReporting {}

// MARK: - FeedContainer

extension MainShtorkaStateObject: FeedContainer {
    var sizePublisher: AnyPublisher<ShtorkaSize, Never> {
        // The feed is built inside the sheet at the size it already renders; only a change asks it for anything.
        $size.removeDuplicates().dropFirst().eraseToAnyPublisher()
    }

    var dismissPublisher: AnyPublisher<Void, Never> {
        $isPresented.filter { !$0 }.map { _ in () }.eraseToAnyPublisher()
    }

    var contentCollapsedPublisher: AnyPublisher<Bool, Never> {
        $isContentCollapsed.removeDuplicates().eraseToAnyPublisher()
    }
}
