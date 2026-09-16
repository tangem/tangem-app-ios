//
//  CollectiblesGeoblockViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI
import SwiftUI

@MainActor
final class CollectiblesGeoblockViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Properties

    private let provider: any CollectiblesGeoblockProvider
    private let floatingSheetPresenter: FloatingSheetPresenter

    private var status: CollectiblesRegionStatus?

    var isRestricted: Bool {
        status == .restricted
    }

    // MARK: - Publishers

    @Published var isRestrictionsPresented = false

    // MARK: - Init

    init(
        provider: some CollectiblesGeoblockProvider = CollectiblesGeoblockMockProvider(),
        floatingSheetPresenter: FloatingSheetPresenter = InjectedValues[\.floatingSheetPresenter]
    ) {
        self.provider = provider
        self.floatingSheetPresenter = floatingSheetPresenter
    }

    // MARK: - Methods

    func load() async {
        do {
            status = try await provider.load()
        } catch {
            status = nil
        }
    }

    func presentRestrictions() {
        guard #available(iOS 26.0, *) else {
            floatingSheetPresenter.enqueue(sheet: self)
            return
        }

        isRestrictionsPresented = true
    }

    func close() {
        guard #available(iOS 26.0, *) else {
            floatingSheetPresenter.removeActiveSheet()
            return
        }

        isRestrictionsPresented = false
    }
}
