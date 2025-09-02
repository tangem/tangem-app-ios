//
//  YieldPromoBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import SwiftUI

@MainActor
final class YieldPromoBottomSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - View State

    @Published var state: ViewState

    private(set) var tokenImage: Image
    private(set) var networkFee: String
    private(set) var maximumFee: String

    // MARK: - Init

    init(state: ViewState, tokenImage: Image, networkFee: String, maximumFee: String) {
        self.tokenImage = tokenImage
        self.networkFee = networkFee
        self.maximumFee = maximumFee
        self.state = state
    }

    // MARK: - Public Implementation

    func onCloseTapAction() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func onShowFeePolicy() {
        state = .feePolicy
    }

    func onShowStartEarning() {
        state = .startYearing
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
