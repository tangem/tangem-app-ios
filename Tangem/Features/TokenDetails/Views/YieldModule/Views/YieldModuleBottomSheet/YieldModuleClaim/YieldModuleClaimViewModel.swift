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

final class YieldModuleClaimViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.alertPresenter)
    private var alertPresenter: any AlertPresenter

    // MARK: - ViewState

    let tangemIconProvider: TangemIconProvider
    let confirmTransactionPolicy: ConfirmTransactionPolicy

    // MARK: - Published

    @Published
    private(set) var viewData: YieldModuleClaimViewData

    @Published
    private(set) var serviceFeeState: YieldFeeSectionState = .init()

    @Published
    private(set) var serviceFeeNote: String?

    @Published
    private(set) var networkFeeState: YieldFeeSectionState = .init()

    @Published
    private(set) var notification: YieldModuleNotificationBannerParams?

    @Published
    private(set) var isProcessingRequest = false

    @Published
    private(set) var isActionButtonAvailable = false

    var buttonTitle: String {
        Localization.yieldModuleClaimButtonTitle(viewData.total)
    }

    // MARK: - Dependencies

    private let walletModel: any WalletModel
    private weak var coordinator: YieldModuleActiveCoordinator?
    private let claimInteractor: YieldIncentivesClaimInteractor
    private let notificationManager: YieldModuleNotificationManager

    private lazy var feeFormatter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)
    private let mapper: YieldModuleClaimViewDataMapper
    private var prepareTask: Task<Void, Never>?
    private var shownFee: ShownFee?

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

        mapper = YieldModuleClaimViewDataMapper(blockchain: walletModel.tokenItem.blockchain)
        viewData = mapper.map(summary: summary)

        start()
    }

    // MARK: - Public Implementation

    func onClaimTap() {
        guard let shownFee else {
            return
        }

        isProcessingRequest = true

        Task { @MainActor [weak self, walletModel] in
            defer { self?.isProcessingRequest = false }

            do {
                let submitted = try await self?.claimInteractor.claim(confirmedFee: shownFee.confirmedValue) { amount in
                    amount.value <= walletModel.getFeeCurrencyBalance()
                }

                guard submitted != nil else {
                    return
                }

                self?.coordinator?.closeClaimSheet()
            } catch let error where error.isCancellationError {
                // Rewards stay untouched, and the sheet keeps the prepared state.
            } catch YieldIncentivesClaimInteractor.ClaimError.submissionUnresolved {
                // The claim may already be on its way, and the banner says so — an error would contradict it.
                self?.coordinator?.closeClaimSheet()
            } catch {
                self?.handle(claimError: error)
            }
        }
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
        shownFee = nil
        serviceFeeNote = nil
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

            viewData = mapper.map(summary: prepared.summary)
            serviceFeeState = serviceFeeState.withFeeState(.loaded(text: makeServiceFeeText(for: prepared)))
            serviceFeeNote = mapper.serviceFeeRate(for: prepared.summary).map(Localization.yieldModuleClaimServiceFeeNote)
            networkFeeState = networkFeeState.withFeeState(.loaded(text: feeText))

            let isFeeCovered = feeValue <= walletModel.getFeeCurrencyBalance()

            if !isFeeCovered {
                notification = makeNotEnoughFeeNotification()
            }

            shownFee = ShownFee(value: feeValue, shownAt: Date())
            isActionButtonAvailable = isFeeCovered
        } catch {
            guard !Task.isCancelled else {
                return
            }

            serviceFeeState = serviceFeeState.withFeeState(.noData)
            serviceFeeNote = nil
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

        if case YieldIncentivesClaimInteractor.ClaimError.feeIncreased = claimError {
            refresh()
            alertPresenter.present(alert: AlertBuilder.makeOkGotItAlert(message: Localization.sendNotificationHighFeeTitle))
            return
        }

        alertPresenter.present(alert: AlertBuilder.makeOkErrorAlert(message: Localization.yieldModuleClaimErrorMessage))
    }

    private func makeServiceFeeText(for prepared: YieldIncentivesClaimInteractor.PreparedClaim) -> String {
        BalanceFormatter().formatFiatBalance(
            prepared.calldata.totalEstimatedServiceFeeUsd,
            currencyCode: AppConstants.usdCurrencyCode
        )
    }

    private func isDeferredClaim(error: Error) -> Bool {
        guard let claimError = error as? YieldIncentivesClaimInteractor.ClaimError else {
            return false
        }

        switch claimError {
        case .validationFailed, .rewardsUnavailable, .moduleUnavailable:
            return true
        case .claimAlreadyInFlight, .insufficientFee, .feeIncreased, .submissionUnresolved:
            return false
        }
    }
}

// MARK: - Identifiable

extension YieldModuleClaimViewModel: Identifiable {}

// MARK: - Shown Fee

private extension YieldModuleClaimViewModel {
    struct ShownFee {
        let value: Decimal
        let shownAt: Date

        var confirmedValue: Decimal? {
            Date().timeIntervalSince(shownAt) < Constants.feeRelevanceInterval ? nil : value
        }
    }

    enum Constants {
        static let feeRelevanceInterval: TimeInterval = 60
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
