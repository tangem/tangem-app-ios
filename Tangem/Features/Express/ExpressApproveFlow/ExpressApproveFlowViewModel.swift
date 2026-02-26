//
//  ExpressApproveFlowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemUI

final class ExpressApproveFlowViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - ViewState

    @Published private(set) var state: ViewState

    // MARK: - Init

    init(
        input: ExpressApproveViewModel.Input,
        router: ExpressApproveRoutable
    ) {
        let approveViewModel = ExpressApproveViewModel(input: input, coordinator: router)
        state = .approve(approveViewModel)
    }
}

// MARK: - ViewState

extension ExpressApproveFlowViewModel {
    enum ViewState {
        case approve(ExpressApproveViewModel)
    }
}
