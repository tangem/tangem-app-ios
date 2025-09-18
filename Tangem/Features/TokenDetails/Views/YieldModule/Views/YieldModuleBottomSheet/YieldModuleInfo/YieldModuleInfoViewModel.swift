//
//  YieldInfoBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemFoundation

@MainActor
final class YieldModuleInfoViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.safariManager) var safariManager: SafariManager
    @Injected(\.floatingSheetPresenter) var floatingSheetPresenter: FloatingSheetPresenter

    // MARK: - View State

    @Published
    var viewState: ViewState {
        didSet {
            previousFlow = oldValue
        }
    }

    @Published
    var notificationBannerParams: YieldModuleViewConfigs.YieldModuleNotificationBannerParams? = nil

    private var previousFlow: ViewState?
    private let walletModel: any WalletModel
    private let readMoreLink = URL(string: "https://tangem.com")!

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

    func onBackAction() {
        previousFlow.map { viewState = $0 }
    }

    func onShowApproveSheet() {
        viewState = .approve(
            params: .init(
                tokenName: walletModel.tokenItem.name,
                networkFee: "5.1", // [REDACTED_TODO_COMMENT]
                readMoreAction: { [weak self] in
                    self?.openReadMoreLink()
                },
                mainAction: {}
            )
        )
    }

    func onShowStopEarningSheet() {
        guard case .earnInfo(let params) = viewState else {
            onCloseTapAction()
            return
        }

        viewState = .stopEarning(
            params: .init(
                tokenName: params.tokenName,
                networkFee: params.networkFee,
                readMoreAction: params.onReadMoreAction,
                mainAction: params.onStopEarningAction
            )
        )
    }

    // MARK: - Private Implementation

    private func openReadMoreLink() {
        safariManager.openURL(readMoreLink)
    }

    private func createNotificationBannerIfNeeded() -> YieldModuleViewConfigs.YieldModuleNotificationBannerParams? {
        switch viewState {
        case .stopEarning, .approve:
            // [REDACTED_TODO_COMMENT]
            guard true else { return nil }

            return YieldAttentionBannerFactory.makeNotEnoughFeeCurrencyBanner(
                feeTokenItem: walletModel.feeTokenItem,
                navigationAction: { [weak self] in

                    self?.onCloseTapAction()
                }
            )

        case .earnInfo:
            // [REDACTED_TODO_COMMENT]
            if true {
                return YieldAttentionBannerFactory.makeApproveRequiredBanner(navigationAction: {})
            }
        }
    }
}

extension YieldModuleInfoViewModel {
    enum ViewState: Identifiable, Equatable {
        case earnInfo(params: YieldModuleViewConfigs.EarnInfoParams)
        case stopEarning(params: YieldModuleViewConfigs.CommonParams)
        case approve(params: YieldModuleViewConfigs.CommonParams)

        var id: String {
            switch self {
            case .earnInfo:
                "earnInfo"
            case .stopEarning:
                "stopEarning"
            case .approve:
                "approve"
            }
        }
    }
}

// MARK: - FloatingSheetContentViewModel

extension YieldModuleInfoViewModel: FloatingSheetContentViewModel {}
