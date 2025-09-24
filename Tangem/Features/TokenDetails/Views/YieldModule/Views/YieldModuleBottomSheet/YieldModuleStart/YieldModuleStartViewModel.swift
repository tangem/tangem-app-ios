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
            previousState = oldValue
            createNotificationBannerIfNeeded()
        }
    }

    @Published
    var notificationBannerParams: YieldModuleViewConfigs.YieldModuleNotificationBannerParams? = nil

    @Published
    private(set) var networkFeeState: NetworkFeeSection.State = .loading

    private var previousState: ViewState?
    private(set) var walletModel: any WalletModel
    private(set) var maximumFee = 0
    private var yieldModuleNotificationInteractor = YieldModuleNoticeInteractor()

    // MARK: - Init

    init(walletModel: any WalletModel, viewState: ViewState) {
        self.viewState = viewState
        self.walletModel = walletModel
        createNotificationBannerIfNeeded()
    }

    // MARK: - Navigation

    func onCloseTapAction() {
        runTask(in: self) { vm in
            vm.floatingSheetPresenter.removeActiveSheet()
        }
    }

    func onShowFeePolicy() {
        viewState = .feePolicy
    }

    func onStartEarningTap() {
        yieldModuleNotificationInteractor.markWithdrawalAlertShouldShow(for: walletModel.tokenItem)
    }

    func onBackAction() {
        previousState.map { viewState = $0 }
    }

    // MARK: - Public Implementation

    func onStartEarningSheetAppear() async {}

    // MARK: - Private Implementation

    private func getNetworkFee() {}

    private func createNotificationBannerIfNeeded() {
        if case .startEarning = viewState {
            // [REDACTED_TODO_COMMENT]
            guard true else { return }

            notificationBannerParams = YieldAttentionBannerFactory.makeNotEnoughFeeCurrencyBanner(
                feeTokenItem: walletModel.feeTokenItem,
                navigationAction: { [weak self] in

                    self?.onCloseTapAction()
                }
            )
        }
    }
}

extension YieldModuleStartViewModel {
    enum ViewState: Identifiable, Equatable {
        case rateInfo
        case feePolicy
        case startEarning

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
