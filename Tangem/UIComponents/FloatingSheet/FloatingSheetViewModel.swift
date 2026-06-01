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

    func present(replacingActive sheet: some FloatingSheetContentViewModel) async {
        if activeSheet != nil {
            removeActiveSheet()
            try? await Task.sleep(for: Constants.dismissAnimationDuration)
        }
        enqueue(sheet: sheet)
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

private extension FloatingSheetViewModel {
    enum Constants {
        static let dismissAnimationDuration: Duration = .milliseconds(350)
    }
}

// MARK: - FloatingSheetPresentingStateProvider

extension FloatingSheetViewModel: FloatingSheetPresentingStateProvider {
    var hasPresentedSheetPublisher: AnyPublisher<Bool, Never> {
        $activeSheet.map { $0 != nil }.eraseToAnyPublisher()
    }
}
