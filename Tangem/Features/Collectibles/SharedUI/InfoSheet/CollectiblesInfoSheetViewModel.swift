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

    let model: CollectiblesInfoSheetView.Model

    // MARK: - Publishers

    @Published var isPresented = false

    // MARK: - Init

    init(model: CollectiblesInfoSheetView.Model) {
        self.model = model
    }

    // MARK: - Methods

    func present() {
        guard #available(iOS 26.0, *) else {
            floatingSheetPresenter.enqueue(sheet: self)
            return
        }

        isPresented = true
    }

    func close() {
        guard isPresented else {
            floatingSheetPresenter.removeActiveSheet()
            return
        }

        isPresented = false
    }
}
