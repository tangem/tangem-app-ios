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

    @Injected(\.floatingSheetPresenter) var floatingSheetPresenter: FloatingSheetPresenter

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

    private var previousState: ViewState?
    private let walletModel: any WalletModel
    private let openFeeCurrencyAction: () -> Void

    // MARK: - Init

    init(walletModel: any WalletModel, openFeeCurrencyAction: @escaping () -> Void) {
        self.walletModel = walletModel
        self.openFeeCurrencyAction = openFeeCurrencyAction

        viewState = .earnInfo(
            params: .init(
                earningsData: .init(totalEarnings: "WIP", chartData: [:]),
                status: .active(approveRequired: true),
                apy: "WIP",
                availableFunds: .init(availableBalance: "WIP"),
                transferMode: "WIP",
                tokenName: walletModel.tokenItem.name,
                tokenSymbol: walletModel.tokenItem.token?.symbol ?? "",
                readMoreUrl: Constants.earnInfoReadMoreUrl
            )
        )

        createNotificationBannerIfNeeded()
    }

    // MARK: - Navigation

    func onApproveTap() {
        floatingSheetPresenter.removeActiveSheet()
    }

    func onStopEarningTap() {
        floatingSheetPresenter.removeActiveSheet()
    }

    func onCloseTap() {
        runTask(in: self) { vm in
            vm.floatingSheetPresenter.removeActiveSheet()
        }
    }

    func onBackTap() {
        previousState.map { viewState = $0 }
    }

    func onShowStopEarningSheet() {
        guard case .earnInfo(let params) = viewState else {
            onCloseTap()
            return
        }

        viewState = .stopEarning(
            params: .init(
                tokenName: params.tokenName,
                networkFee: "5.1",
                readMoreUrl: Constants.stopEarningReadMoreUrl, // [REDACTED_TODO_COMMENT]
                mainAction: { [weak self] in
                    self?.onStopEarningTap()
                }
            )
        )
    }

    // MARK: - Private Implementation

    private func createInitialViewState(with walletModel: any WalletModel) -> ViewState {
        .earnInfo(
            params: .init(
                earningsData: .init(totalEarnings: "WIP", chartData: [:]),
                status: .active(approveRequired: true),
                apy: "WIP",
                availableFunds: .init(availableBalance: "WIP"),
                transferMode: "WIP",
                tokenName: walletModel.tokenItem.name,
                tokenSymbol: walletModel.tokenItem.token?.symbol ?? "",
                readMoreUrl: Constants.earnInfoReadMoreUrl,
            )
        )
    }

    private func showApproveSheet() {
        viewState = .approve(
            params: .init(
                tokenName: walletModel.tokenItem.name,
                networkFee: "5.1",
                readMoreUrl: Constants.approveReadMoreUrl, // [REDACTED_TODO_COMMENT]
                mainAction: {}
            )
        )
    }

    private func createNotificationBannerIfNeeded() {
        let params: YieldModuleViewConfigs.YieldModuleNotificationBannerParams?

        switch viewState {
        case .stopEarning, .approve:
            // [REDACTED_TODO_COMMENT]
            guard true else { return }

            params = YieldAttentionBannerFactory.makeNotEnoughFeeCurrencyBanner(
                feeTokenItem: walletModel.feeTokenItem,
                navigationAction: { [weak self] in
                    self?.onCloseTap()
                    self?.openFeeCurrencyAction()
                }
            )

        case .earnInfo:
            // [REDACTED_TODO_COMMENT]
            if true {
                params = YieldAttentionBannerFactory.makeApproveRequiredBanner(navigationAction: { [weak self] in
                    self?.showApproveSheet()
                })
            }
        }

        notificationBannerParams = params
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

private extension YieldModuleInfoViewModel {
    enum Constants {
        static let earnInfoReadMoreUrl = URL(string: "https://tangem.com")!
        static let stopEarningReadMoreUrl = URL(string: "https://tangem.com")!
        static let approveReadMoreUrl = URL(string: "https://tangem.com")!
    }
}
