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

    private var bag: Set<AnyCancellable> = []

    nonisolated init() {
        Task { @MainActor in
            bind()
        }
    }

    private func bind() {
        FloatingSheetVisibility.shared.$visibleSheets
            .withWeakCaptureOf(self)
            // custom case - need improve for cover all cases (when enqueue, paused/resume sheets and etc.)
            .sink { viewModel, visibleSheets in
                if let sheet = viewModel.activeSheet, !visibleSheets.contains(ObjectIdentifier(type(of: sheet))) {
                    viewModel.activeSheet = nil
                    viewModel.sheetsQueue.append(sheet)
                    return
                }

                if let sheet = viewModel.sheetsQueue.first(where: { visibleSheets.contains(ObjectIdentifier(type(of: $0))) }) {
                    viewModel.activeSheet = sheet
                    viewModel.sheetsQueue.removeAll(where: { $0.id == sheet.id })
                    return
                }
            }
            .store(in: &bag)
    }

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
