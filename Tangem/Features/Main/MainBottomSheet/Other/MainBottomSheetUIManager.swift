//
//  MainBottomSheetUIManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import class UIKit.UIImage
import TangemFoundation

final class MainBottomSheetUIManager {
    private(set) var hasPendingSnapshotUpdate = false

    private let isShownSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private let isExpandedSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private let footerSnapshotSubject: PassthroughSubject<FooterSnapshot, Never> = .init()
    private let footerSnapshotUpdateTriggerSubject: PassthroughSubject<Void, Never> = .init()
    private var pendingFooterSnapshotUpdateCompletions: [() -> Void] = []
    private var pendingShow: Task<Void, Error>?

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

    func show(after delay: TimeInterval = 0) {
        ensureOnMainQueue()

        pendingShow?.cancel()
        pendingShow = nil

        guard delay > 0 else {
            isShownSubject.send(true)
            return
        }

        pendingShow = Task.delayed(withDelay: delay) { @MainActor [weak self] in
            try Task.checkCancellation()
            self?.pendingShow = nil
            self?.isShownSubject.send(true)
        }
    }

    func hide(shouldUpdateFooterSnapshot: Bool = true) {
        ensureOnMainQueue()

        // Navigation can hide the sheet before its cold-start presentation has run.
        pendingShow?.cancel()
        pendingShow = nil

        guard isShown else {
            return
        }

        isExpandedSubject.send(false)

        let isShown = false

        guard shouldUpdateFooterSnapshot else {
            isShownSubject.send(isShown)
            return
        }

        hasPendingSnapshotUpdate = true
        setFooterSnapshotNeedsUpdate { [weak self] in
            // Workaround: delaying hiding main bottom sheet roughly for the duration of one frame so that the UI
            // has a chance to actually render an updated view snapshot.
            // Dispatching to the next runloop tick (via `DispatchQueue.main.async`) doesn't work reliably enough
            // because not every runloop tick is used for rendering.
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.mainBottomSheetHidingDelay) {
                guard let self else {
                    return
                }

                self.isShownSubject.send(isShown)
                self.hasPendingSnapshotUpdate = false
            }
        }
    }
}

// MARK: - Snapshot management

extension MainBottomSheetUIManager {
    /// Provides updated snapshot.
    var footerSnapshotPublisher: some Publisher<FooterSnapshot, Never> { footerSnapshotSubject }

    /// Triggers snapshot update.
    var footerSnapshotUpdateTriggerPublisher: some Publisher<Void, Never> { footerSnapshotUpdateTriggerSubject }

    func setFooterSnapshots(lightAppearanceSnapshotImage: UIImage?, darkAppearanceSnapshotImage: UIImage?) {
        ensureOnMainQueue()

        let footerSnapshot = FooterSnapshot(
            lightAppearance: lightAppearanceSnapshotImage,
            darkAppearance: darkAppearanceSnapshotImage
        )

        footerSnapshotSubject.send(footerSnapshot)

        let completions = pendingFooterSnapshotUpdateCompletions
        pendingFooterSnapshotUpdateCompletions.removeAll(keepingCapacity: true)
        completions.forEach { $0() }
    }

    private func setFooterSnapshotNeedsUpdate(with completion: @escaping () -> Void) {
        pendingFooterSnapshotUpdateCompletions.append(completion)
        footerSnapshotUpdateTriggerSubject.send()
    }
}

// MARK: - Auxiliary types

extension MainBottomSheetUIManager {
    struct FooterSnapshot {
        let lightAppearance: UIImage?
        let darkAppearance: UIImage?
    }
}

// MARK: - Constants

private extension MainBottomSheetUIManager {
    enum Constants {
        static let mainBottomSheetHidingDelay: TimeInterval = 1.0 / 60.0
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
