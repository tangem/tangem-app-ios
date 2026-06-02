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
        AppLogger.info("[FloatingSheet.enqueue] sheet=\(type(of: sheet)) active=\(activeSheetTypeDescription) queueCount=\(sheetsQueue.count) isPaused=\(isPaused)")
        if activeSheet == nil, !isPaused {
            activeSheet = sheet
        } else {
            sheetsQueue.append(sheet)
        }
        AppLogger.info("[FloatingSheet.enqueue] after active=\(activeSheetTypeDescription) queueCount=\(sheetsQueue.count)")
    }

    func replaceActive(with sheet: some FloatingSheetContentViewModel) async {
        AppLogger.info("[FloatingSheet.replaceActive] sheet=\(type(of: sheet)) active=\(activeSheetTypeDescription) queueCount=\(sheetsQueue.count) isPaused=\(isPaused)")
        let hadActive = activeSheet != nil
        if hadActive {
            activeSheet = nil
            try? await Task.sleep(for: Constants.dismissAnimationDuration)
        }

        if isPaused {
            sheetsQueue.insert(sheet, at: 0)
        } else {
            activeSheet = sheet
        }
        AppLogger.info("[FloatingSheet.replaceActive] after active=\(activeSheetTypeDescription) queueCount=\(sheetsQueue.count)")
    }

    func removeActiveSheet() {
        AppLogger.info("[FloatingSheet.removeActiveSheet] active=\(activeSheetTypeDescription) queueCount=\(sheetsQueue.count) isPaused=\(isPaused)")
        guard !isPaused else {
            if sheetsQueue.isNotEmpty {
                sheetsQueue.removeFirst()
            }

            return
        }

        activeSheet = sheetsQueue.isEmpty
            ? nil
            : sheetsQueue.removeFirst()
        AppLogger.info("[FloatingSheet.removeActiveSheet] after active=\(activeSheetTypeDescription) queueCount=\(sheetsQueue.count)")
    }

    private var activeSheetTypeDescription: String {
        activeSheet.map { String(describing: type(of: $0)) } ?? "nil"
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
