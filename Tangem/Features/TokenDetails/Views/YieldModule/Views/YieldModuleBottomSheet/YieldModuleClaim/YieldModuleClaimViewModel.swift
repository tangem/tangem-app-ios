//
//  YieldModuleClaimViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUI
import TangemMacro

final class YieldModuleClaimViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.alertPresenter)
    private var alertPresenter: any AlertPresenter

    // MARK: - ViewState

    let tangemIconProvider: TangemIconProvider
    let confirmTransactionPolicy: ConfirmTransactionPolicy

    var feeCurrencySymbol: String {
        walletModel.feeTokenItem.currencySymbol
    }

    // MARK: - Published

    @Published
    private(set) var viewState: ViewState

    @Published
    private(set) var serviceFeeState: YieldFeeSectionState = .init()

    @Published
    private(set) var networkFeeState: YieldFeeSectionState = .init()

    @Published
    private(set) var notification: YieldModuleNotificationBannerParams?

    @Published
    private(set) var isProcessingRequest = false

    @Published
    private(set) var isActionButtonAvailable = false

    // MARK: - Dependencies

    private let walletModel: any WalletModel
    private weak var coordinator: YieldModuleActiveCoordinator?
    private let claimInteractor: YieldIncentivesClaimInteractor
    private let notificationManager: YieldModuleNotificationManager

    private lazy var feeFormatter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)
    private let mapper: YieldModuleClaimViewDataMapper
    private var prepareTask: Task<Void, Never>?
    private var preparedClaim: YieldIncentivesClaimInteractor.PreparedClaim?

    // MARK: - Init

    init(
        summary: YieldIncentivesRewardsSummary,
        walletModel: any WalletModel,
        coordinator: YieldModuleActiveCoordinator?,
        claimInteractor: YieldIncentivesClaimInteractor,
        notificationManager: YieldModuleNotificationManager,
        tangemIconProvider: TangemIconProvider,
        confirmTransactionPolicy: ConfirmTransactionPolicy
    ) {
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.claimInteractor = claimInteractor
        self.notificationManager = notificationManager
        self.tangemIconProvider = tangemIconProvider
        self.confirmTransactionPolicy = confirmTransactionPolicy

        mapper = YieldModuleClaimViewDataMapper(
            blockchain: walletModel.tokenItem.blockchain,
            storage: Self.resolveStorage(for: walletModel)
        )
        viewState = .claim(mapper.map(summary: summary))

        start()
    }

    // MARK: - Public Implementation

    func onClaimTap() {
        guard let preparedClaim else {
            return
        }

        isProcessingRequest = true

        Task { @MainActor [weak self, walletModel] in
            defer { self?.isProcessingRequest = false }

            do {
                let submitted = try await self?.claimInteractor.claim(prepared: preparedClaim) { amount in
                    amount.value <= walletModel.getFeeCurrencyBalance()
                }

                guard let self, let submitted else {
                    return
                }

                viewState = .success(mapper.mapSuccess(summary: submitted.preparation.summary))
            } catch let error where error.isCancellationError {
                // Rewards stay untouched, and the sheet keeps the prepared state.
            } catch YieldIncentivesClaimInteractor.ClaimError.submissionUnresolved(_) {
                // The claim may already be on its way, and the banner says so — an error would contradict it.
                self?.coordinator?.closeClaimSheet()
            } catch {
                self?.handle(claimError: error)
            }
        }
    }

    func onCloseTap() {
        guard !isProcessingRequest else {
            return
        }

        coordinator?.closeClaimSheet()
    }

    func onToTokenTap() {
        coordinator?.dismiss()
    }

    // MARK: - Private Implementation

    private func start() {
        refresh()
    }

    /// Only the latest run may write to the sheet: a slower earlier one would otherwise land on top of it.
    private func refresh(updatingBalances: Bool = false) {
        prepareTask?.cancel()
        prepareTask = Task { @MainActor [weak self] in
            self?.setLoadingState()

            if updatingBalances {
                await self?.walletModel.update(silent: true, options: .balances)

                guard !Task.isCancelled else {
                    return
                }
            }

            await self?.prepare()
        }
    }

    @MainActor
    private func setLoadingState() {
        isActionButtonAvailable = false
        notification = nil
        preparedClaim = nil
        serviceFeeState = serviceFeeState.withFeeState(.loading)
        networkFeeState = networkFeeState.withFeeState(.loading)
    }

    @MainActor
    private func prepare() async {
        do {
            let prepared = try await claimInteractor.prepare()
            let feeValue = prepared.fee.totalFeeAmount.value
            let feeText = try await feeFormatter.createFeeString(from: feeValue)

            guard !Task.isCancelled else {
                return
            }

            viewState = .claim(mapper.map(summary: prepared.summary))
            serviceFeeState = serviceFeeState.withFeeState(
                .loaded(text: mapper.mapServiceFee(
                    amountUsd: prepared.calldata.totalEstimatedServiceFeeUsd,
                    summary: prepared.summary
                ))
            )
            networkFeeState = networkFeeState.withFeeState(.loaded(text: feeText))

            let isFeeCovered = feeValue <= walletModel.getFeeCurrencyBalance()

            if !isFeeCovered {
                notification = makeNotEnoughFeeNotification()
            }

            preparedClaim = prepared
            isActionButtonAvailable = isFeeCovered
        } catch {
            guard !Task.isCancelled else {
                return
            }

            serviceFeeState = serviceFeeState.withFeeState(.noData)
            networkFeeState = networkFeeState.withFeeState(.noData)
            notification = isDeferredClaim(error: error) ? makeRewardsUnavailableNotification() : makeFeeErrorNotification()
        }
    }

    @MainActor
    private func handle(claimError: Error) {
        guard !isDeferredClaim(error: claimError) else {
            // The rewards moved out from under the sheet — refresh instead of reporting a failure.
            refresh()
            return
        }

        // The fee grew past the balance between the sheet and the signature.
        if case YieldIncentivesClaimInteractor.ClaimError.insufficientFee = claimError {
            refresh(updatingBalances: true)
            return
        }

        if case YieldIncentivesClaimInteractor.ClaimError.preparationExpired = claimError {
            refresh()
            return
        }

        alertPresenter.present(alert: AlertBuilder.makeOkErrorAlert(message: Localization.yieldModuleClaimErrorMessage))
    }

    private static func resolveStorage(for walletModel: any WalletModel) -> YieldModuleClaimViewData.Storage? {
        let userWalletRepository: UserWalletRepository = InjectedValues[\.userWalletRepository]

        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == walletModel.userWalletId }) else {
            return nil
        }

        let provider = TokenHeaderProvider(userWalletName: userWalletModel.name, account: walletModel.account)

        switch provider.makeHeader() {
        case .account(let name, let icon):
            return .account(name: name, icon: icon)

        case .wallet(let name, hasOnlyOneWallet: false):
            return .wallet(name: name)

        case .wallet(_, hasOnlyOneWallet: true):
            return nil
        }
    }

    private func isDeferredClaim(error: Error) -> Bool {
        guard let claimError = error as? YieldIncentivesClaimInteractor.ClaimError else {
            return false
        }

        return claimError.isClaimNoLongerAvailable
    }
}

// MARK: - FloatingSheetContentViewModel

extension YieldModuleClaimViewModel: FloatingSheetContentViewModel {}

// MARK: - View State

extension YieldModuleClaimViewModel {
    @CaseFlagable
    enum ViewState: Equatable {
        case claim(YieldModuleClaimViewData)
        case success(YieldModuleClaimSuccessViewData)
    }
}

// MARK: - Notification Builders

private extension YieldModuleClaimViewModel {
    func makeNotEnoughFeeNotification() -> YieldModuleNotificationBannerParams {
        notificationManager.createNotEnoughFeeCurrencyNotification { [weak self, walletModel] in
            self?.coordinator?.openFeeCurrency(walletModel: walletModel)
        }
    }

    func makeRewardsUnavailableNotification() -> YieldModuleNotificationBannerParams {
        notificationManager.createRewardsUnavailableNotification { [weak self] in
            self?.refresh()
        }
    }

    func makeFeeErrorNotification() -> YieldModuleNotificationBannerParams {
        notificationManager.createFeeUnreachableNotification { [weak self] in
            self?.refresh(updatingBalances: true)
        }
    }
}
