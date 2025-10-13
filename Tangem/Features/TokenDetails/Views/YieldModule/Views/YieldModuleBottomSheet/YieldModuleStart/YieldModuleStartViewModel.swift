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

final class YieldModuleStartViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    @Injected(\.userWalletRepository)
    private var userWalletRepository: any UserWalletRepository

    // MARK: - View State

    @Published
    var viewState: ViewState {
        didSet {
            previousState = oldValue
        }
    }

    private var previousState: ViewState?

    // MARK: - Published

    @Published
    private(set) var notificationBannerParams: YieldModuleViewConfigs.YieldModuleNotificationBannerParams? = nil

    @Published
    private(set) var networkFeeState: LoadableTextView.State = .loading

    @Published
    private(set) var tokenFeeState: LoadableTextView.State = .loading

    @Published
    private(set) var maximumFeeState: LoadableTextView.State = .loading

    @Published
    private(set) var chartState: YieldChartContainerState = .loading

    @Published
    private(set) var isProcessingStartRequest: Bool = false

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    private weak var coordinator: YieldModulePromoCoordinator?
    private let yieldManagerInteractor: YieldManagerInteractor

    private lazy var feeConverter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)

    // MARK: - Properties

    private(set) var maximumFee: Decimal = 0

    var isButtonEnabled: Bool {
        switch viewState {
        case .startEarning:
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

        default:
            return true
        }
    }

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        viewState: ViewState,
        coordinator: YieldModulePromoCoordinator?,
        yieldManagerInteractor: YieldManagerInteractor
    ) {
        self.viewState = viewState
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.yieldManagerInteractor = yieldManagerInteractor
    }

    // MARK: - Navigation

    @MainActor
    func onCloseTap() {
        floatingSheetPresenter.removeActiveSheet()
        runTask(in: self) { vm in
            await vm.yieldManagerInteractor.clearAll()
        }
    }

    @MainActor
    func onShowFeePolicy() {
        viewState = .feePolicy
    }

    @MainActor
    func onStartEarnTap() {
        let token = walletModel.tokenItem
        isProcessingStartRequest = true

        runTask(in: self) { vm in
            await vm.yieldManagerInteractor.enter(with: token)
            vm.coordinator?.dismiss()
        }
    }

    @MainActor
    func onBackAction() {
        previousState.map { viewState = $0 }
    }

    // MARK: - Public Implementation

    @MainActor
    func fetchChartData() async {
        chartState = .loading

        do {
            let chartData = try await yieldManagerInteractor.getChartData()
            chartState = .loaded(chartData)
        } catch {
            chartState = .error(action: { [weak self] in
                await self?.fetchChartData()
            })
        }
    }

    @MainActor
    func fetchMaximumFee() async {
        maximumFeeState = .loading

        do {
            let (coinFee, _) = try await yieldManagerInteractor.getMaxFee()
            let feeInTokens = try await feeConverter.makeFeeInTokenString(from: coinFee)
            maximumFeeState = .loaded(text: feeInTokens)
        } catch {
            maximumFeeState = .noData
        }
    }

    func fetchNetworkFee() async {
        await runOnMain {
            tokenFeeState = .loading
            networkFeeState = .loading
        }

        do {
            let feeInCoins = try await yieldManagerInteractor.getEnterFee()
            let feeValue = feeInCoins.totalFeeAmount.value

            let convertedFee = try await feeConverter.createFeeString(from: feeValue)
            let feeInTokens = try await feeConverter.makeFeeInTokenString(from: feeValue)

            await runOnMain {
                networkFeeState = .loaded(text: convertedFee)
                tokenFeeState = .loaded(text: feeInTokens)

                if feeValue > walletModel.getFeeCurrencyBalance(amountType: walletModel.tokenItem.amountType) {
                    showNotEnoughFeeNotification()
                }
            }

        } catch {
            await runOnMain {
                tokenFeeState = .noData
                networkFeeState = .noData
                showFeeErrorNotification()
            }
        }
    }

    // MARK: - Private Implementation

    private func showNotEnoughFeeNotification() {
        notificationBannerParams = .notEnoughFeeCurrency(
            feeCurrencyName: walletModel.feeTokenItem.name,
            tokenIcon: NetworkImageProvider().provide(by: walletModel.feeTokenItem.blockchain, filled: true)
        ) { [weak self] in
            if let selectedUserWalletModel = self?.userWalletRepository.selectedModel,
               let feeWalletModel = self?.getFeeCurrencyWalletModel(in: selectedUserWalletModel) {
                self?.onCloseTap()
                self?.coordinator?.openFeeCurrency(for: feeWalletModel, userWalletModel: selectedUserWalletModel)
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

// MARK: - View State

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
