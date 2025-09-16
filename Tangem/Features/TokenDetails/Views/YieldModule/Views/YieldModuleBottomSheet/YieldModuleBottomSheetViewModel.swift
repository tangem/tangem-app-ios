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
        Task {
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func onStopEarningTap() {
        // WIP
    }

    func onShowFeePolicy(params: YieldModuleParams.FeePolicyParams) {
        flow = .feePolicy(params: params)
    }

    func onBackAction() {
        previousFlow.map { flow = $0 }
    }

    func onShowApproveSheet() {
        guard case .earnInfo(let params) = flow else {
            onCloseTapAction()
            return
        }

        flow = .approve(
            params: .init(
                tokenName: params.tokenName,
                networkFee: params.networkFee,
                feeCurrencyInfo: params.feeCurrencyInfo,
                readMoreAction: params.onReadMoreAction,
                mainAction: params.onApproveAction
            )
        )
    }

    func onShowStopEarningSheet() {
        guard case .earnInfo(let params) = flow else {
            onCloseTapAction()
            return
        }

        flow = .stopEarning(
            params: .init(
                tokenName: params.tokenName,
                networkFee: params.networkFee,
                feeCurrencyInfo: params.feeCurrencyInfo,
                readMoreAction: params.onReadMoreAction,
                mainAction: params.onStopEarningAction
            )
        )
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

    func createNoficiationBannerIfNeeded() -> YieldModuleParams.YieldModuleBottomSheetNotificationBannerParams? {
        switch flow {
        case .startEarning, .approve, .stopEarning:
            guard let info = flow.feeCurrencyInfo else { return nil }
            return .notEnoughFeeCurrency(
                feeCurrencyName: info.feeCurrencyName,
                tokenIcon: info.feeCurrencyIcon,
                buttonAction: { [weak self] in
                    info.goToFeeCurrencyAction()
                    self?.onCloseTapAction()
                }
            )

        case .earnInfo(let params):
            if case .active(true) = params.status {
                return .approveNeeded(
                    buttonAction: { [weak self] in
                        self?.flow = .approve(
                            params: .init(
                                tokenName: params.tokenName,
                                networkFee: params.networkFee,
                                feeCurrencyInfo: params.feeCurrencyInfo,
                                readMoreAction: params.onReadMoreAction,
                                mainAction: params.onApproveAction
                            )
                        )
                    })
            }
            return nil

        case .feePolicy, .rateInfo:
            return nil
        }
    }
}

extension YieldModuleBottomSheetViewModel {
    enum Flow: Identifiable, Equatable {
        case rateInfo(params: YieldModuleParams.RateInfoParams)
        case feePolicy(params: YieldModuleParams.FeePolicyParams)
        case startEarning(params: YieldModuleParams.StartEarningParams)
        case earnInfo(params: YieldModuleParams.EarnInfoParams)
        case stopEarning(params: YieldModuleParams.СommonParams)
        case approve(params: YieldModuleParams.СommonParams)

        // MARK: - Identifiable

        var id: String {
            switch self {
            case .rateInfo:
                "rateInfo"
            case .feePolicy:
                "feePolicy"
            case .startEarning:
                "startEarning"
            case .earnInfo:
                "earnInfo"
            case .stopEarning:
                "stopEarning"
            case .approve:
                "approve"
            }
        }

        var feeCurrencyInfo: YieldModuleParams.FeeCurrencyInfo? {
            switch self {
            case .startEarning(let params):
                return params.feeCurrencyInfo
            case .stopEarning(let params):
                return params.feeCurrencyInfo
            case .approve(let params):
                return params.feeCurrencyInfo
            case .earnInfo(let params):
                return params.feeCurrencyInfo
            default:
                return nil
            }
        }
    }
}
