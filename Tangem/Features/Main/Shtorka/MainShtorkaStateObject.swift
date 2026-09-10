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
    @Published private(set) var detents = ShtorkaDetents()
    var expansionProgressPublisher: AnyPublisher<CGFloat, Never> {
        heights.expansionProgressPublisher
    }

    private let heights = FeedDetentHeights()
    private var bag = Set<AnyCancellable>()

    init() {
        heights.detentsPublisher.assign(to: &$detents)

        bind()
    }

    func collapse() {
        size = .collapsed
    }

    func expand() {
        size = .full
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
    }

    func present() {
        guard !isPresented else {
            return
        }

        withTransaction(.withoutAnimations()) {
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
