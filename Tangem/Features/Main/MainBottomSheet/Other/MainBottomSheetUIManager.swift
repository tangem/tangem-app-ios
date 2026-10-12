//
//  MainBottomSheetUIManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class MainBottomSheetUIManager {
    private let isShownSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private let isExpandedSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private var pendingShow: Task<Void, Error>?
    private var pendingShowCompletions: [() -> Void] = []
    private var isShowRequested = false

    deinit {
        pendingShow?.cancel()
    }
}

// MARK: - Visibility management

extension MainBottomSheetUIManager {
    var isShown: Bool { isShownSubject.value }
    var isShownPublisher: some Publisher<Bool, Never> { isShownSubject }

    /// Whether the sheet is dragged out over the main screen, in either of the two presentation modes.
    var isExpanded: Bool { isExpandedSubject.value }

    func setExpanded(_ isExpanded: Bool) {
        ensureOnMainQueue()

        isExpandedSubject.send(isExpanded)
    }

    func requestShow() {
        ensureOnMainQueue()

        isShowRequested = true
    }

    func showIfRequested() {
        ensureOnMainQueue()

        guard isShowRequested else {
            return
        }

        show()
    }

    /// `completion` runs once the sheet is asked for. A newer `show` carries it over; a `hide` that drops the
    /// pending show runs it at once, since there is no sheet left to wait for.
    func show(after delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        ensureOnMainQueue()

        isShowRequested = false
        pendingShow?.cancel()
        pendingShow = nil

        if let completion {
            pendingShowCompletions.append(completion)
        }

        guard delay > 0 else {
            isShownSubject.send(true)
            runPendingShowCompletions()
            return
        }

        pendingShow = Task.delayed(withDelay: delay) { @MainActor [weak self] in
            try Task.checkCancellation()
            self?.pendingShow = nil
            self?.isShownSubject.send(true)
            self?.runPendingShowCompletions()
        }
    }

    func hide() {
        ensureOnMainQueue()

        // Navigation can hide the sheet before its cold-start presentation has run.
        isShowRequested = false
        pendingShow?.cancel()
        pendingShow = nil
        runPendingShowCompletions()

        guard isShown else {
            return
        }

        isExpandedSubject.send(false)
        isShownSubject.send(false)
    }
}

private extension MainBottomSheetUIManager {
    func runPendingShowCompletions() {
        let completions = pendingShowCompletions
        pendingShowCompletions.removeAll()
        completions.forEach { $0() }
    }
}

// MARK: - Dependency injection

private struct MainBottomSheetUIManagerKey: InjectionKey {
    static var currentValue = MainBottomSheetUIManager()
}

extension InjectedValues {
    var mainBottomSheetUIManager: MainBottomSheetUIManager {
        get { Self[MainBottomSheetUIManagerKey.self] }
        set { Self[MainBottomSheetUIManagerKey.self] = newValue }
    }
}
