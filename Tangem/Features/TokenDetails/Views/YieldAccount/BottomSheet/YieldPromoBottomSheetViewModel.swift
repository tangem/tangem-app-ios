//
//  YieldPromoBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

@MainActor
final class YieldPromoBottomSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - View State

    @Published var state: ViewState

    // MARK: - Init

    init(state: ViewState) {
        self.state = state
    }

    // MARK: - Public Implementation

    func onCloseTapAction() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

extension YieldPromoBottomSheetViewModel {
    enum ViewState: Identifiable, Equatable {
        case feePolicy
        case startYearing

        // MARK: - Identifiable

        var id: String {
            switch self {
            case .feePolicy:
                "feePolicy"
            case .startYearing:
                "startYearing"
            }
        }
    }
}
