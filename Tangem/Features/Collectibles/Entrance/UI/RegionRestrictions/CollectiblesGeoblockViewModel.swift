//
//  CollectiblesGeoblockViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

@MainActor
final class CollectiblesGeoblockViewModel: ObservableObject {
    // MARK: - Properties

    private let provider: any CollectiblesGeoblockProvider

    private var status: CollectiblesRegionStatus?

    let restrictionsSheetViewModel = CollectiblesInfoSheetViewModel(model: .regionRestrictions)

    var isRestricted: Bool {
        status == .restricted
    }

    // MARK: - Init

    init(provider: some CollectiblesGeoblockProvider = CollectiblesGeoblockMockProvider()) {
        self.provider = provider
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
        restrictionsSheetViewModel.present()
    }
}
