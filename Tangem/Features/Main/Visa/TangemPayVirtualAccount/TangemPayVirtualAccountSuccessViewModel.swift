//
//  TangemPayVirtualAccountSuccessViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
final class TangemPayVirtualAccountSuccessViewModel: ObservableObject, Identifiable {
    let id = UUID()

    private weak var coordinator: TangemPayVirtualAccountSuccessRoutable?

    init(coordinator: TangemPayVirtualAccountSuccessRoutable) {
        self.coordinator = coordinator

        Analytics.log(.visaVATopupSuccessScreenActivation)
    }

    func close() {
        coordinator?.closeVirtualAccountSuccess()
    }
}
