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

    func onShowStopEarningSheet() {
        if case .earnInfo(let params) = flow {
            flow = .stopEarning(params: .init(tokenName: params.blockchainName, networkFee: params.networkFee))
        } else {
            onCloseTapAction()
        }
    }
}

extension YieldPromoBottomSheetViewModel {
    enum Flow: Identifiable, Equatable {
        case rateInfo(params: RateInfoParams)
        case feePolicy(params: FeePolicyParams)
        case startYearing(params: StartEarningParams)
        case approve(params: ApproveParams)
        case stopEarning(params: StopEarningParams)
        case earnInfo(params: EarnInfoParams)

        // MARK: - Identifiable

        var id: String {
            switch self {
            case .rateInfo:
                "rateInfo"
            case .feePolicy:
                "feePolicy"
            case .startYearing:
                "startYearing"
            case .approve:
                "approve"
            case .stopEarning:
                "stopEarning"
            case .earnInfo:
                "earnInfo"
            }
        }
    }
}

extension YieldPromoBottomSheetViewModel {
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

    struct ApproveParams: Equatable {
        let networkFee: String
    }

    struct StopEarningParams: Equatable {
        let tokenName: String
        let networkFee: String
    }

    struct EarnInfoParams: Equatable {
        let availableFunds: String
        let chartData: YieldModuleChartData
        let transferMode: String
        let status: String
        let blockchainName: String
        let networkFee: String
        let tokenName: String
    }
}
