//
//  YieldModuleBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import SwiftUI

@MainActor
final class YieldModuleBottomSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - View State

    @Published var flow: Flow {
        didSet {
            previousFlow = oldValue
        }
    }

    private var previousFlow: Flow?

    // MARK: - Init

    init(flow: Flow) {
        self.flow = flow
    }

    // MARK: - Public Implementation

    func onCloseTapAction() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func onShowFeePolicy(params: YieldModuleBottomSheetParams.FeePolicyParams) {
        flow = .feePolicy(params: params)
    }

    func onBackAction() {
        previousFlow.map { flow = $0 }
    }

    func onShowFeePolicyTap() {
        guard case .startEarning(let params) = flow else {
            onCloseTapAction()
            return
        }

        flow = .feePolicy(
            params: .init(
                tokenName: params.tokenName,
                networkFee: params.networkFee,
                maximumFee: params.maximumFee,
                blockchainName: params.blockchainName
            )
        )
    }

    func onStartEarningTap() {
        // [REDACTED_TODO_COMMENT]
    }
}

extension YieldModuleBottomSheetViewModel {
    enum Flow: Identifiable, Equatable {
        case rateInfo(params: YieldModuleBottomSheetParams.RateInfoParams)
        case feePolicy(params: YieldModuleBottomSheetParams.FeePolicyParams)
        case startEarning(params: YieldModuleBottomSheetParams.StartEarningParams)

        // MARK: - Identifiable

        var id: String {
            switch self {
            case .rateInfo:
                "rateInfo"
            case .feePolicy:
                "feePolicy"
            case .startEarning:
                "startEarning"
            }
        }
    }
}
