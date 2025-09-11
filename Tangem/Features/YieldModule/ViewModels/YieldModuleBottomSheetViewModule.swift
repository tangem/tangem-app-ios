//
//  YieldModuleBottomSheetViewModule.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
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

    func onShowFeePolicy(params: FeePolicyParams) {
        flow = .feePolicy(params: params)
    }

    func onBackAction() {
        previousFlow.map { flow = $0 }
    }
}

extension YieldModuleBottomSheetViewModel {
    enum Flow: Identifiable, Equatable {
        case rateInfo(params: RateInfoParams)
        case feePolicy(params: FeePolicyParams)
        case startEarning(params: StartEarningParams)

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

extension YieldModuleBottomSheetViewModel {
    struct StartEarningParams: Equatable {
        let tokenName: String
        let tokenIcon: Image
        let networkFee: String
        let maximumFee: String
        let blockchainName: String
    }

    struct RateInfoParams: Equatable {
        let lastYearReturns: [String: Double]
    }

    struct FeePolicyParams: Equatable {
        let currentFee: String
        let maximumFee: String
        let tokenName: String
        let blockchainName: String
    }
}
