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

    @Injected(\.floatingSheetPresenter)
    var floatingSheetPresenter: FloatingSheetPresenter

    @Injected(\.userWalletRepository)
    private var userWalletRepository: any UserWalletRepository

    // MARK: - View State

    @Published
    var viewState: ViewState {
        didSet {
            previousState = oldValue
            notificationBannerParams = nil
        }
    }

    private var previousState: ViewState?

    // MARK: - Published

    @Published
    var notificationBannerParams: YieldModuleViewConfigs.YieldModuleNotificationBannerParams? = nil

    @Published
    private(set) var networkFeeState: LoadableTextView.State = .loading

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    private weak var feeCurrencyNavigator: (any FeeCurrencyNavigating)?

    private lazy var feeConverter = YieldModuleFeeFormatter(
        feeCurrency: walletModel.feeTokenItem,
        token: walletModel.tokenItem,
        maximumFee: maximumFee
    )

    // MARK: - Properties

    private(set) var maximumFee: Decimal = 0
    private(set) var readMoreURLString: URL = TangemBlogUrlBuilder().url(post: .fee)

    private let onGiveApproveAction: () -> Void
    private let onStopEarnAction: () -> Void

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

    init(
        walletModel: any WalletModel,
        feeCurrencyNavigator: any FeeCurrencyNavigating,
        onGiveApproveAction: @escaping () -> Void,
        onStopEarnAction: @escaping () -> Void
    ) {
        self.walletModel = walletModel
        self.feeCurrencyNavigator = feeCurrencyNavigator
        self.onGiveApproveAction = onGiveApproveAction
        self.onStopEarnAction = onStopEarnAction

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

    func onCloseTap() {
        runTask(in: self) { vm in
            vm.floatingSheetPresenter.removeActiveSheet()
        }
    }

    func onBackTap() {
        previousState.map { viewState = $0 }
    }

    func onShowStopEarningSheet() {
        viewState = .stopEarning
    }

    // MARK: - Public Implementation

    func onApproveTap() {
        floatingSheetPresenter.removeActiveSheet()
        onGiveApproveAction()
    }

    func onStopEarningTap() {
        floatingSheetPresenter.removeActiveSheet()
        onStopEarnAction()
    }

    func fetchNetworkFee() async {
        networkFeeState = .loading
        notificationBannerParams = nil

        try? await Task.sleep(seconds: 2)

        if Bool.random() {
            // [REDACTED_TODO_COMMENT]
            let networkFee: Decimal = 0.12
            if let converted = await feeConverter.createFeeString(from: networkFee) {
                networkFeeState = .loaded(text: converted)

                if networkFee > walletModel.getFeeCurrencyBalance(amountType: walletModel.tokenItem.amountType) {
                    showNotEnoughFeeNotification()
                }

            } else {
                showFeeErrorNotification()
                networkFeeState = .noData
            }
        } else {
            showFeeErrorNotification()
            networkFeeState = .noData
        }
    }

    // MARK: - Private Implementation

    private func showApproveSheet() {
        viewState = .approve
    }

    private func showNotEnoughFeeNotification() {
        notificationBannerParams = .notEnoughFeeCurrency(
            feeCurrencyName: walletModel.feeTokenItem.name,
            tokenIcon: NetworkImageProvider().provide(by: walletModel.feeTokenItem.blockchain, filled: true)
        ) { [weak self] in
            guard let self else { return }

            if let selectedUserWalletModel = userWalletRepository.selectedModel,
               let feeWalletModel = getFeeCurrencyWalletModel(in: selectedUserWalletModel) {
                onCloseTap()
                feeCurrencyNavigator?.openFeeCurrency(for: feeWalletModel, userWalletModel: selectedUserWalletModel)
            }
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

    private func getFeeCurrencyWalletModel(in userWalletModel: any UserWalletModel) -> (any WalletModel)? {
        guard let selectedUserModel = userWalletRepository.selectedModel,
              let feeCurrencyWalletModel = selectedUserModel.walletModelsManager.walletModels.first(where: {
                  $0.tokenItem == walletModel.feeTokenItem
              })
        else {
            assertionFailure("Fee currency '\(walletModel.feeTokenItem.name)' for currency '\(walletModel.tokenItem.name)' not found")
            return nil
        }

        return feeCurrencyWalletModel
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
