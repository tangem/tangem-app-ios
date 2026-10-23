//
//  CollectiblesInfoSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

@MainActor
final class CollectiblesInfoSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Properties

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    private let actionTiming: ActionTiming

    private var presentation: Presentation = .floating
    private var pendingAction: (() -> Void)?

    // MARK: - Publishers

    @Published var isPresented = false
    @Published private(set) var model: CollectiblesInfoSheetView.Model

    // MARK: - Init

    init(
        model: CollectiblesInfoSheetView.Model,
        actionTiming: ActionTiming = .afterDismiss
    ) {
        self.model = model
        self.actionTiming = actionTiming
    }

    // MARK: - Methods

    func present() {
        guard #available(iOS 26.0, *) else {
            presentation = .floating
            floatingSheetPresenter.enqueue(sheet: self)
            return
        }

        presentation = .sheet
        isPresented = true
    }

    func present(with model: CollectiblesInfoSheetView.Model) {
        self.model = model
        present()
    }

    func primary() {
        perform(model.primaryButton.action)
    }

    func secondary() {
        perform(model.secondaryButton?.action)
    }

    func close() {
        switch presentation {
        case .sheet:
            isPresented = false
        case .floating:
            floatingSheetPresenter.removeActiveSheet()
        case .dismissing:
            return
        }

        presentation = .dismissing
    }

    func didDismiss() {
        presentation = .dismissing

        let action = pendingAction
        pendingAction = nil
        action?()
    }
}

// MARK: - Action timing

extension CollectiblesInfoSheetViewModel {
    enum ActionTiming {
        case immediately
        case afterDismiss
    }
}

// MARK: - Private logic

private extension CollectiblesInfoSheetViewModel {
    enum Presentation {
        case floating
        case sheet
        case dismissing
    }

    func perform(_ action: (() -> Void)?) {
        guard presentation != .dismissing else { return }

        guard presentation == .sheet, actionTiming == .afterDismiss else {
            close()
            action?()
            return
        }

        pendingAction = action
        close()
    }
}
