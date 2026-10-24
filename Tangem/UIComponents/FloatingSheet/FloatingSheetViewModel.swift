//
//  FloatingSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

final class FloatingSheetViewModel: FloatingSheetPresenter, ObservableObject {
    private var sheetsQueue = [any FloatingSheetContentViewModel]()
    private var isPaused = false

    @Published private(set) var activeSheet: (any FloatingSheetContentViewModel)?

    nonisolated init() {}

    func enqueue(sheet: some FloatingSheetContentViewModel) {
        if activeSheet == nil, !isPaused {
            activeSheet = sheet
        } else {
            sheetsQueue.append(sheet)
        }
    }

    func removeActiveSheet() {
        guard !isPaused else {
            if sheetsQueue.isNotEmpty {
                sheetsQueue.removeFirst()
            }

            return
        }

        activeSheet = sheetsQueue.isEmpty
            ? nil
            : sheetsQueue.removeFirst()
    }

    func removeSheet(withId id: String) {
        guard activeSheet?.id != id else {
            removeActiveSheet()
            return
        }

        sheetsQueue.removeAll { $0.id == id }
    }

    func removeAllSheets() {
        activeSheet = nil
        sheetsQueue.removeAll()
    }

    func pauseSheetsDisplaying() {
        guard !isPaused else { return }

        isPaused = true

        let lastActiveSheet = activeSheet
        activeSheet = nil

        if let lastActiveSheet {
            sheetsQueue.insert(lastActiveSheet, at: 0)
        }
    }

    func resumeSheetsDisplaying() {
        guard isPaused else { return }

        isPaused = false

        if !sheetsQueue.isEmpty {
            activeSheet = sheetsQueue.removeFirst()
        }
    }
}

// MARK: - FloatingSheetPresentingStateProvider

extension FloatingSheetViewModel: FloatingSheetPresentingStateProvider {
    var hasPresentedSheet: Bool {
        activeSheet != nil
    }

    var hasPresentedSheetPublisher: AnyPublisher<Bool, Never> {
        $activeSheet.map { $0 != nil }.eraseToAnyPublisher()
    }

    var activeSheetIdPublisher: AnyPublisher<String?, Never> {
        $activeSheet.map { $0?.id }.eraseToAnyPublisher()
    }

    func containsSheet(withId id: String) -> Bool {
        activeSheet?.id == id || sheetsQueue.contains { $0.id == id }
    }
}
