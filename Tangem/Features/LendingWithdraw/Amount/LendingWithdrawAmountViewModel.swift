//
//  LendingWithdrawAmountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class LendingWithdrawAmountViewModel: ObservableObject {
    typealias StateModel = LendingAmountContentView.StateModel
    typealias Action = LendingWithdrawAmountContentView.Action

    let amountField: AmountInputFieldModel

    @Published private(set) var state: StateModel

    private(set) var loadTask: Task<Void, Never>?

    private let model: LendingWithdrawModel
    private let sourceToken: SendTransferableToken
    private let analyticsLogger: LendingAnalyticsLogger
    private let interactor: SendAmountInteractor
    private weak var router: LendingWithdrawAmountRoutable?
    private let isShown = CurrentValueSubject<Bool, Never>(false)
    private let isFeeOutdated = CurrentValueSubject<Bool, Never>(false)
    private var feeRefresh: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        model: LendingWithdrawModel,
        sourceToken: SendTransferableToken,
        analyticsLogger: LendingAnalyticsLogger,
        router: LendingWithdrawAmountRoutable?
    ) {
        self.model = model
        self.sourceToken = sourceToken
        self.analyticsLogger = analyticsLogger
        self.router = router

        interactor = CommonSendAmountInteractor(
            sourceTokenInput: model,
            sourceTokenAmountInput: model,
            receiveTokenInput: nil,
            receiveTokenOutput: nil,
            receiveTokenAmountInput: nil,
            receiveTokenAmountOutput: nil,
            validator: LendingWithdrawAmountValidator { [weak model] in model?.availableToWithdraw ?? 0 },
            amountModifier: nil,
            notificationService: nil,
            saver: CommonSendAmountInteractorSaver(
                sourceTokenAmountInput: model,
                sourceTokenAmountOutput: model,
                receiveTokenInput: nil,
                receiveTokenOutput: nil
            )
        )

        amountField = AmountInputFieldModel(tokenItem: sourceToken.tokenItem, fiatItem: sourceToken.fiatItem)
        state = StateModel(
            header: nil,
            source: LendingAmountContentView.Source(
                tokenIconInfo: TokenIconInfoBuilder().build(from: sourceToken.tokenItem, isCustom: sourceToken.isCustom),
                title: LendingWithdrawText.source,
                subtitle: ""
            ),
            fee: .loading,
            canChangeFeeSpeed: false,
            notice: LendingWithdrawText.notice,
            submitTitle: LendingWithdrawText.withdraw,
            isSubmitEnabled: false
        )

        bind()
    }

    func onAppear() {
        let isFirstAppearance = loadTask == nil

        if isFirstAppearance {
            analyticsLogger.logWithdrawScreenOpened(positionBalance: model.positionBalance, availableToWithdraw: model.knownAvailableToWithdraw)
        }

        isShown.send(true)

        guard isFirstAppearance else {
            return
        }

        loadTask = Task { @MainActor [weak model] in
            _ = await model?.loadAvailableToWithdraw()
            model?.updateFees()
        }
    }

    func onDisappear() {
        isShown.send(false)
    }

    func handle(_ action: Action) {
        switch action {
        case .info:
            router?.openHowItWorks()
        case .close:
            router?.closeWithdrawal()
        case .max:
            analyticsLogger.logMax()
            setShare(percent: 100)
        case .share(let percent):
            analyticsLogger.logPercent(percent)
            setShare(percent: percent)
        case .fee:
            router?.openFeeSelector()
        case .retryFee:
            model.updateFees()
        case .withdraw:
            router?.openConfirmation()
        }
    }
}

// MARK: - Private

private extension LendingWithdrawAmountViewModel {
    func bind() {
        amountField.onValueChanged = { [weak self] value in
            guard let self else { return }

            let amount = try? interactor.update(sourceAmount: value)
            amountField.updateAlternativeUI(amount: amount)
        }

        amountField.$amountType
            .dropFirst()
            .removeDuplicates()
            .receiveOnMain()
            .sink { [weak self] amountType in
                guard let self else { return }

                analyticsLogger.logCurrencyToggled(to: amountType)
                let amount = try? interactor.update(sourceType: amountType)
                amountField.updateAmountsUI(amount: amount)
            }
            .store(in: &bag)

        Publishers.CombineLatest3(
            interactor.sourceFieldInfoPublisher,
            model.selectedFeePublisher.map(\.value.value),
            sourceToken.availableBalanceProvider.balanceTypePublisher.map(\.value)
        )
        .map { [currencySymbol = sourceToken.tokenItem.currencySymbol] info, fee, balance in
            Self.bottomInfo(interactorInfo: info, fee: fee, balance: balance, currencySymbol: currencySymbol)
        }
        .receiveOnMain()
        .sink { [weak self] info in
            self?.amountField.bottomInfoText = info
        }
        .store(in: &bag)

        Publishers.CombineLatest4(
            interactor.sourceFieldInfoPublisher.map { info in
                guard case .error = info else { return true }
                return false
            },
            model.selectedFeePublisher.compactMap(\.value.value).map(Optional.some).prepend(nil),
            sourceToken.availableBalanceProvider.balanceTypePublisher.map(\.value),
            isShown
        )
        .map { isAmountValid, fee, balance, isShown -> LendingAnalyticsLogger.Notice? in
            guard isShown else { return nil }

            return LendingAnalyticsLogger.Notice.withdraw(
                isAmountValid: isAmountValid,
                isFeeCovered: Self.isFeeCovered(fee: fee, balance: balance)
            )
        }
        .removeDuplicates()
        .compactMap { $0 }
        .sink { [analyticsLogger] notice in
            analyticsLogger.logNotice(notice)
        }
        .store(in: &bag)

        model.availableToWithdrawPublisher
            .receiveOnMain()
            .sink { [weak self] available in
                guard let self else { return }

                let balance = BalanceFormatter().formatCryptoBalance(available, tokenItem: sourceToken.tokenItem)
                state.source.subtitle = LendingWithdrawText.availableBalance(balance)
                interactor.validateExternalSourceAmount(model.sourceAmount.value)
            }
            .store(in: &bag)

        model.selectedFeePublisher
            .receiveOnMain()
            .sink { [weak self] tokenFee in
                self?.state.fee = LendingFee(tokenFee)
            }
            .store(in: &bag)

        model.supportFeeSelectionPublisher
            .receiveOnMain()
            .sink { [weak self] canChangeFeeSpeed in
                self?.state.canChangeFeeSpeed = canChangeFeeSpeed
            }
            .store(in: &bag)

        Publishers.CombineLatest3(interactor.isValidPublisher, model.isFeeCoveredPublisher, isFeeOutdated)
            .map { isAmountValid, isFeeCovered, isFeeOutdated in isAmountValid && isFeeCovered && !isFeeOutdated }
            .removeDuplicates()
            .receiveOnMain()
            .sink { [weak self] isWithdrawEnabled in
                self?.state.isSubmitEnabled = isWithdrawEnabled
            }
            .store(in: &bag)

        model.sourceAmountPublisher
            .map { $0.value?.crypto }
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.isFeeOutdated.send(true)
            }
            .store(in: &bag)

        model.sourceAmountPublisher
            .map { $0.value?.crypto }
            .removeDuplicates()
            .dropFirst()
            .debounce(for: Constants.feeUpdateDelay, scheduler: DispatchQueue.main)
            .sink { [weak self] amount in
                self?.refreshFee(amount: amount)
            }
            .store(in: &bag)
    }

    func refreshFee(amount: Decimal?) {
        model.updateFees()

        feeRefresh?.cancel()
        feeRefresh = Task { @MainActor [weak self] in
            var awaited: Task<Void, Never>?

            while let latest = self?.model.feeUpdateTask, latest != awaited {
                await latest.value
                awaited = latest

                guard !Task.isCancelled else {
                    return
                }
            }

            guard let self, !Task.isCancelled, model.sourceAmount.value?.crypto == amount else {
                return
            }

            isFeeOutdated.send(false)
        }
    }

    static func bottomInfo(
        interactorInfo: SendAmountViewModel.BottomInfoTextType?,
        fee: BSDKFee?,
        balance: Decimal?,
        currencySymbol: String
    ) -> SendAmountViewModel.BottomInfoTextType? {
        guard !isFeeCovered(fee: fee, balance: balance) else {
            return interactorInfo
        }

        return .error(LendingWithdrawText.notEnough(currencySymbol))
    }

    static func isFeeCovered(fee: BSDKFee?, balance: Decimal?) -> Bool {
        guard let fee, fee.amount.type == .coin, let balance else {
            return true
        }

        return balance >= fee.amount.value
    }

    func setShare(percent: Int) {
        let share = (model.availableToWithdraw * Decimal(percent) / 100)
            .rounded(scale: sourceToken.tokenItem.decimalCount, roundingMode: .down)

        let amount = try? interactor.update(sourceCryptoAmount: share)
        amountField.updateAmountsUI(amount: amount)
    }
}

// MARK: - Constants

private extension LendingWithdrawAmountViewModel {
    enum Constants {
        static let feeUpdateDelay: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300)
    }
}
