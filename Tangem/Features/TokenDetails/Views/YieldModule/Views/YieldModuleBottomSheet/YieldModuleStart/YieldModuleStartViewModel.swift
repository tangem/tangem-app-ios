//
//  YieldModuleStartViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import SwiftUI
import TangemFoundation

@MainActor
final class YieldModuleStartViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - View State

    @Published
    var viewState: ViewState {
        didSet {
            viewState = oldValue
        }
    }

    @Published
    var notificationBannerParams: YieldModuleViewConfigs.YieldModuleNotificationBannerParams? = nil

    private var previousState: ViewState?
    private let walletModel: any WalletModel

    // MARK: - Init

    init(walletModel: any WalletModel, viewState: ViewState) {
        self.viewState = viewState
        self.walletModel = walletModel
    }

    // MARK: - Navigation

    func onCloseTapAction() {
        runTask(in: self) { vm in
            vm.floatingSheetPresenter.removeActiveSheet()
        }
    }

    func onShowFeePolicy(params: YieldModuleViewConfigs.StartEarningParams) {
        viewState = .feePolicy(
            params: .init(
                tokenName: params.tokenName,
                networkFee: params.networkFee,
                maximumFee: params.maximumFee,
                blockchainName: params.blockchainName
            )
        )
    }

    func onStartEarningTap() {}

    func onBackAction() {
        previousState.map { viewState = $0 }
    }

    // MARK: - Private Implementation

    private func createNotificationBannerIfNeeded() -> YieldModuleViewConfigs.YieldModuleNotificationBannerParams? {
        if case .startEarning = viewState {
            // [REDACTED_TODO_COMMENT]
            guard true else { return nil }

            return YieldAttentionBannerFactory.makeNotEnoughFeeCurrencyBanner(
                feeTokenItem: walletModel.feeTokenItem,
                navigationAction: { [weak self] in

                    self?.onCloseTapAction()
                }
            )
        }

        return nil
    }
}

extension YieldModuleStartViewModel {
    enum ViewState: Identifiable, Equatable {
        case rateInfo(params: YieldModuleViewConfigs.RateInfoParams)
        case feePolicy(params: YieldModuleViewConfigs.FeePolicyParams)
        case startEarning(params: YieldModuleViewConfigs.StartEarningParams)

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

// MARK: - FloatingSheetContentViewModel

extension YieldModuleStartViewModel: FloatingSheetContentViewModel {}
