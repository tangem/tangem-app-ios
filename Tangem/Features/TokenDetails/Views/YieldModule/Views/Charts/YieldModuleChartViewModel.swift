//
//  YieldModuleChartViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class YieldModuleChartViewModel: ObservableObject {
    // MARK: - Published

    @Published
    var state: YieldChartState = .loading

    // MARK: - Dependencies

    private let chartServices = YieldChartService()

    // MARK: - Public Implementation

    @MainActor
    func loadData() async {
        state = .loading

        do {
            let data = try await chartServices.getChartData()
            state = .loaded(data)
        } catch {
            state = .error(action: loadData)
        }
    }
}
