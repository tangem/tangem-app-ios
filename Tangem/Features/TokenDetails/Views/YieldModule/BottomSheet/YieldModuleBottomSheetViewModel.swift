//
//  YieldModuleBottomSheetViewModel.swift
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

    @Published private(set) var flow: Flow {
        didSet {
            previousFlow = oldValue
        }
    }

    var feeCurrencyInfo: YieldModuleBottomSheetParams.FeeCurrencyInfo? {
        switch flow {
        case .startEarning(let params): return params.feeCurrencyInfo
        case .stopEarning(let params): return params.feeCurrencyInfo
        case .approve(let params): return params.feeCurrencyInfo
        default: return nil
        }
    }

    private(set) var bottomBannerModel: YieldModuleBottomSheetBottomBannerParams?

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

    func onShowApproveNeededSheet() {
        if case .earnInfo(let earnParams) = flow {
            let params = YieldModuleBottomSheetParams.ApproveParams(
                networkFee: earnParams.networkFee,
                feeCurrencyInfo: earnParams.feeCurrencyInfo
            )

            flow = .approve(params: params)
        } else {
            onCloseTapAction()
        }
    }

    func onShowStopEarningSheet() {
        if case .earnInfo(let earnParams) = flow {
            let params = YieldModuleBottomSheetParams.StopEarningParams(
                tokenName: earnParams.tokenName,
                networkFee: earnParams.networkFee,
                feeCurrencyInfo: earnParams.feeCurrencyInfo
            )

            flow = .stopEarning(params: params)

        } else {
            onCloseTapAction()
        }
    }
}

extension YieldModuleBottomSheetViewModel {
    enum Flow: Identifiable, Equatable {
        case rateInfo(params: YieldModuleBottomSheetParams.RateInfoParams)
        case feePolicy(params: YieldModuleBottomSheetParams.FeePolicyParams)
        case startEarning(params: YieldModuleBottomSheetParams.StartEarningParams)
        case approve(params: YieldModuleBottomSheetParams.ApproveParams)
        case stopEarning(params: YieldModuleBottomSheetParams.StopEarningParams)
        case earnInfo(params: YieldModuleBottomSheetParams.EarnInfoParams)

        // MARK: - Identifiable

        var id: String {
            switch self {
            case .rateInfo:
                "rateInfo"
            case .feePolicy:
                "feePolicy"
            case .startEarning:
                "startEarning"
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

enum YieldModuleBottomSheetParams {
    struct StartEarningParams: Equatable {
        let tokenName: String
        let tokenIcon: Image
        let networkFee: String
        let maximumFee: String
        let blockchainName: String
        let feeCurrencyInfo: FeeCurrencyInfo?
    }

    struct RateInfoParams: Equatable {
        let lastYearReturns: [String: Double]
    }

    struct FeePolicyParams: Equatable {
        let networkFee: String
        let maximumFee: String
        let tokenName: String
        let blockchainName: String
    }

    struct ApproveParams: Equatable {
        let networkFee: Decimal
        let feeCurrencyInfo: FeeCurrencyInfo?
    }

    struct StopEarningParams: Equatable {
        let tokenName: String
        let networkFee: Decimal
        let feeCurrencyInfo: FeeCurrencyInfo?
    }

    struct FeeCurrencyInfo: Equatable {
        let feeCurrencyName: String
        let feeCurrencyIcon: Image
        let feeCurrencySymbol: String
        let goToFeeCurrencyAction: () -> Void

        static func == (lhs: FeeCurrencyInfo, rhs: FeeCurrencyInfo) -> Bool {
            lhs.feeCurrencyName == rhs.feeCurrencyName &&
                lhs.feeCurrencyIcon == rhs.feeCurrencyIcon &&
                lhs.feeCurrencySymbol == rhs.feeCurrencySymbol
        }
    }

    struct EarnInfoParams: Equatable {
        let tokenName: String
        let availableFunds: String
        let chartData: YieldModuleChartData
        let transferMode: String
        let status: String
        let networkFee: Decimal
        let approveNeeded: Bool
        let feeCurrencyInfo: FeeCurrencyInfo?

        static func == (lhs: EarnInfoParams, rhs: EarnInfoParams) -> Bool {
            lhs.availableFunds == rhs.availableFunds &&
                lhs.chartData == rhs.chartData &&
                lhs.transferMode == rhs.transferMode &&
                lhs.status == rhs.status &&
                lhs.networkFee == rhs.networkFee &&
                lhs.approveNeeded == rhs.approveNeeded &&
                lhs.feeCurrencyInfo == rhs.feeCurrencyInfo
        }
    }
}
