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

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel

    private lazy var feeConverter = YieldModuleFeeFormatter(
        feeCurrency: walletModel.feeTokenItem,
        token: walletModel.tokenItem,
        maximumFee: 10
    )

    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()

    // MARK: - View State

    @Published
    var viewState: ViewState {
        didSet {
            previousState = oldValue
            notificationBannerParams = nil
        }
    }

    @Published
    var notificationBannerParams: YieldModuleViewConfigs.YieldModuleNotificationBannerParams? = nil

    @Published
    private(set) var networkFeeState: NetworkFeeSection.State = .loading

    private var previousState: ViewState?

    private let openFeeCurrencyAction: () -> Void

    // [REDACTED_TODO_COMMENT]
    var readMoreURLString: String {
        switch viewState {
        case .earnInfo:
            "https://tangem.com"
        case .stopEarning:
            "https://tangem.com"
        case .approve:
            "https://tangem.com"
        }
    }

    var isButtonEnabled: Bool {
        switch viewState {
        case .earnInfo:
            return true

        case .stopEarning, .approve:
            switch (networkFeeState, notificationBannerParams) {
            case (.loaded, .notEnoughFeeCurrency):
                return false
            case (.loaded, .feeUnreachable):
                return false
            case (.loaded, .none):
                return true
            default:
                return false
            }
        }
    }

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
                tokenSymbol: walletModel.tokenItem.token?.symbol ?? ""
            )
        )
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

    private func showNotEnoughFeeNotification() {
        notificationBannerParams = .notEnoughFeeCurrency(
            feeCurrencyName: walletModel.feeTokenItem.name,
            tokenIcon: NetworkImageProvider().provide(by: walletModel.feeTokenItem.blockchain, filled: true)
        ) { [weak self] in
            self?.onCloseTap()
            self?.openFeeCurrencyAction()
        }
    }

    private func showFeeErrorNotification() {
        notificationBannerParams = .feeUnreachable { [weak self] in
            guard let self else { return }
            runTask(in: self) { vm in
                await vm.fetchNetworkFee()
            }
        }
    }

    func onBackTap() {
        previousState.map { viewState = $0 }
    }

    func onShowStopEarningSheet() {
        viewState = .stopEarning
    }

    // MARK: - Public Implementation

    func fetchNetworkFee() async {
        networkFeeState = .loading
        notificationBannerParams = nil

        try! await Task.sleep(seconds: 2)

        if Bool.random() {
            // [REDACTED_TODO_COMMENT]
            let networkFee: Decimal = 0.12
            if let converted = await feeConverter.createFeeString(from: networkFee) {
                networkFeeState = .loaded(fee: converted)

                if networkFee > walletModel.getFeeCurrencyBalance(amountType: walletModel.tokenItem.amountType) {
                    showNotEnoughFeeNotification()
                }

            } else {
                showFeeErrorNotification()
                networkFeeState = .error
            }
        } else {
            showFeeErrorNotification()
            networkFeeState = .error
        }
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
                tokenSymbol: walletModel.tokenItem.token?.symbol ?? ""
            )
        )
    }

    private func showApproveSheet() {
        viewState = .approve
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
        case stopEarning
        case approve

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
