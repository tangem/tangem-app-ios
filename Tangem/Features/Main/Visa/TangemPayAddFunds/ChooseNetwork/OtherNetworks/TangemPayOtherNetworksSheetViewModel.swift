//
//  TangemPayOtherNetworksSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

@MainActor
final class TangemPayOtherNetworksSheetViewModel: FloatingSheetContentViewModel {
    private weak var coordinator: TangemPayOtherNetworksSheetRoutable?

    init(coordinator: TangemPayOtherNetworksSheetRoutable) {
        self.coordinator = coordinator
    }

    func close() {
        coordinator?.closeOtherNetworksSheet()
    }
}
