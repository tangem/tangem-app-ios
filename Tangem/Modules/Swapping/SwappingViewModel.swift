//
//  SwappingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemSwapping
import UIKit
import enum TangemSdk.TangemSdkError

final class SwappingViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var sendCurrencyViewModel: SendCurrencyViewModel?
    @Published var receiveCurrencyViewModel: ReceiveCurrencyViewModel?
    @Published var swapButtonIsLoading: Bool = false

    @Published var sendDecimalValue: DecimalNumberTextField.DecimalValue?
    @Published var refreshWarningRowViewModel: DefaultWarningRowViewModel?
    @Published var highPriceImpactWarningRowViewModel: DefaultWarningRowViewModel?
    @Published var permissionInfoRowViewModel: DefaultWarningRowViewModel?

    @Published var mainButtonIsEnabled: Bool = false
    @Published var mainButtonState: MainButtonState = .swap
    @Published var errorAlert: AlertBinder?

    var informationSectionViewModels: [InformationSectionViewModel] {
        var viewModels: [InformationSectionViewModel] = []

        if let swappingFeeRowViewModel = swappingFeeRowViewModel {
            viewModels.append(.fee(swappingFeeRowViewModel))
        }

        if let feeWarningRowViewModel = feeWarningRowViewModel {
            viewModels.append(.warning(feeWarningRowViewModel))
        }

        if let feeInfoRowViewModel = feeInfoRowViewModel {
            viewModels.append(.warning(feeInfoRowViewModel))
        }

        return viewModels
    }

    @Published private var swappingFeeRowViewModel: SwappingFeeRowViewModel?
    @Published private var feeWarningRowViewModel: DefaultWarningRowViewModel?
    @Published private var feeInfoRowViewModel: DefaultWarningRowViewModel?

    // MARK: - Dependencies

    private let initialSourceCurrency: Currency
    private let swappingInteractor: SwappingInteractor
    private let swappingDestinationService: SwappingDestinationServicing
    private let tokenIconURLBuilder: TokenIconURLBuilding
    private let transactionSender: SwappingTransactionSender
    private let fiatRatesProvider: FiatRatesProviding
    private let userWalletModel: UserWalletModel
    private let currencyMapper: CurrencyMapping
    private let blockchainNetwork: BlockchainNetwork
    private unowned let coordinator: SwappingRoutable

    // MARK: - Private

    private lazy var refreshDataTimer = Timer.publish(every: 10, on: .main, in: .common)
    private var refreshDataTimerBag: AnyCancellable?
    private var bag: Set<AnyCancellable> = []
    private var workingTasks: Set<Task<Void, Error>> = []

    init(
        initialSourceCurrency: Currency,
        swappingInteractor: SwappingInteractor,
        swappingDestinationService: SwappingDestinationServicing,
        tokenIconURLBuilder: TokenIconURLBuilding,
        transactionSender: SwappingTransactionSender,
        fiatRatesProvider: FiatRatesProviding,
        userWalletModel: UserWalletModel,
        currencyMapper: CurrencyMapping,
        blockchainNetwork: BlockchainNetwork,

        coordinator: SwappingRoutable
    ) {
        self.initialSourceCurrency = initialSourceCurrency
        self.swappingInteractor = swappingInteractor
        self.swappingDestinationService = swappingDestinationService
        self.tokenIconURLBuilder = tokenIconURLBuilder
        self.transactionSender = transactionSender
        self.fiatRatesProvider = fiatRatesProvider
        self.userWalletModel = userWalletModel
        self.currencyMapper = currencyMapper
        self.blockchainNetwork = blockchainNetwork
        self.coordinator = coordinator

        Analytics.log(event: .swapScreenOpenedSwap, params: [.token: initialSourceCurrency.symbol])
        setupView()
        bind()
        loadDestinationIfNeeded()
    }

    deinit {
        workingTasks.forEach { $0.cancel() }
    }

    func userDidTapMaxAmount() {
        let sourceBalance = swappingInteractor.getSwappingItems().sourceBalance
        sendDecimalValue = .external(sourceBalance)
        updateSendFiatValue(amount: sourceBalance)
        swappingInteractor.update(amount: sourceBalance)
    }

    func userDidRequestChangeDestination(to currency: Currency) {
        var items = swappingInteractor.getSwappingItems()

        if items.source == initialSourceCurrency {
            items.destination = currency
        } else if items.destination == initialSourceCurrency {
            items.source = currency
        }

        Task { [items] in
            await update(swappingItems: items, shouldRefresh: true)
        }
        .store(in: &workingTasks)
    }

    func userDidTapSwapSwappingItemsButton() {
        Analytics.log(.swapButtonSwipe)
        var items = swappingInteractor.getSwappingItems()

        guard let destination = items.destination else {
            return
        }

        let source = items.source

        items.source = destination
        items.destination = source

        Task { [items] in
            await update(swappingItems: items, shouldRefresh: false)
        }
        .store(in: &workingTasks)

        // If we have amount then we should round and update it with new decimalCount
        guard let amount = sendDecimalValue?.value else {
            return
        }

        let roundedAmount = amount.rounded(scale: items.source.decimalCount, roundingMode: .down)
        sendDecimalValue = .external(roundedAmount)
        updateSendFiatValue(amount: roundedAmount)
        swappingInteractor.update(amount: roundedAmount)
    }

    func userDidTapChangeCurrencyButton() {
        openTokenListView()
    }

    func userDidTapChangeDestinationButton() {
        Analytics.log(.swapReceiveTokenClicked)
        openTokenListView()
    }

    func didTapMainButton() {
        switch mainButtonState {
        case .permitAndSwap:
            Analytics.log(.swapButtonPermitAndSwap)
        // [REDACTED_TODO_COMMENT]
        case .swap:
            swapItems()
        case .givePermission:
            Analytics.log(.swapButtonGivePermission)
            openPermissionView()
        case .insufficientFunds:
            assertionFailure("Button should be disabled")
        }
    }

    func didSendApproveTransaction(transactionData: SwappingTransactionData) {
        swappingInteractor.didSendApprovingTransaction(swappingTxData: transactionData)
    }

    func didClosePermissionSheet() {
        restartTimer()
    }

    func didTapWaringRefresh() {
        swappingInteractor.refresh(type: .full)
    }
}

// MARK: - Navigation

private extension SwappingViewModel {
    func openTokenListView() {
        coordinator.presentSwappingTokenList(sourceCurrency: initialSourceCurrency)
    }

    func openSuccessView(
        result: SwappingResultData,
        transactionData: SwappingTransactionData,
        transactionID: String
    ) {
        let amount = transactionData.sourceCurrency.convertFromWEI(value: transactionData.sourceAmount)
        let source = CurrencyAmount(
            value: amount,
            currency: transactionData.sourceCurrency
        )

        let result = CurrencyAmount(
            value: result.amount,
            currency: transactionData.destinationCurrency
        )

        let inputModel = SwappingSuccessInputModel(
            sourceCurrencyAmount: source,
            resultCurrencyAmount: result,
            transactionID: transactionID
        )

        coordinator.presentSuccessView(inputModel: inputModel)
    }

    func openPermissionView() {
        let state = swappingInteractor.getAvailabilityState()

        guard case .available(let result, let data) = state,
              result.isPermissionRequired,
              let fiatFee = fiatRatesProvider.getSyncFiat(for: data.sourceBlockchain, amount: data.fee) else {
            // If we don't have enough data disable button and refresh()
            mainButtonIsEnabled = false
            swappingInteractor.refresh(type: .full)

            return
        }

        let inputModel = SwappingPermissionInputModel(fiatFee: fiatFee, transactionData: data)

        stopTimer()
        coordinator.presentPermissionView(inputModel: inputModel, transactionSender: transactionSender)
    }
}

// MARK: - View updates

private extension SwappingViewModel {
    func resetViews() {
        refreshWarningRowViewModel = nil
        feeWarningRowViewModel = nil
        permissionInfoRowViewModel = nil
        highPriceImpactWarningRowViewModel = nil
        swapButtonIsLoading = false
    }

    func updateView(swappingItems: SwappingItems) {
        updateSendView(swappingItems: swappingItems)
        updateReceiveView(swappingItems: swappingItems)
    }

    func updateSendView(swappingItems: SwappingItems) {
        let source = swappingItems.source

        sendCurrencyViewModel = SendCurrencyViewModel(
            balance: .loaded(swappingItems.sourceBalance),
            fiatValue: .loading,
            maximumFractionDigits: source.decimalCount,
            canChangeCurrency: source != initialSourceCurrency,
            tokenIcon: mapToSwappingTokenIconViewModel(currency: source)
        )

        updateSendFiatValue(amount: sendDecimalValue?.value)
    }

    func updateSendFiatValue(amount: Decimal?) {
        guard let amount = amount else {
            sendCurrencyViewModel?.update(fiatValue: .loaded(0))
            return
        }

        let source = swappingInteractor.getSwappingItems().source
        if !fiatRatesProvider.hasRates(for: source) {
            sendCurrencyViewModel?.update(fiatValue: .loading)
        }

        Task {
            let fiatValue = try await fiatRatesProvider.getFiat(for: source, amount: amount)

            try Task.checkCancellation()

            await runOnMain {
                sendCurrencyViewModel?.update(fiatValue: .loaded(fiatValue))
            }
        }
        .store(in: &workingTasks)
    }

    func updateReceiveView(swappingItems: SwappingItems) {
        let destination = swappingItems.destination

        let cryptoAmountState: ReceiveCurrencyViewModel.State
        let fiatAmountState: ReceiveCurrencyViewModel.State

        switch swappingInteractor.getAvailabilityState() {
        case .idle, .requiredRefresh:
            cryptoAmountState = .loaded(0)
            fiatAmountState = .loaded(0)
        case .loading:
            cryptoAmountState = .loading
            fiatAmountState = .loading
        case .preview(let result):
            cryptoAmountState = .loaded(result.expectedAmount)
            fiatAmountState = .loading
            updateReceiveCurrencyValue(value: result.expectedAmount)
        case .available(let result, _):
            cryptoAmountState = .loaded(result.amount)
            fiatAmountState = .loading
            updateReceiveCurrencyValue(value: result.amount)
        }

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            balance: swappingItems.destinationBalance,
            canChangeCurrency: destination != initialSourceCurrency,
            cryptoAmountState: cryptoAmountState,
            fiatAmountState: fiatAmountState,
            tokenIcon: mapToSwappingTokenIconViewModel(currency: destination)
        )
    }

    func updateState(state: SwappingAvailabilityState) {
        updateFeeValue(state: state)
        updateMainButton(state: state)

        switch state {
        case .idle:
            resetViews()

            receiveCurrencyViewModel?.update(cryptoAmountState: .loaded(0))
            receiveCurrencyViewModel?.update(fiatAmountState: .loaded(0))

        case .loading(let type):
            swapButtonIsLoading = true

            // Turn on skeletons only for full update
            guard type == .full else { return }

            refreshWarningRowViewModel?.update(rightView: .loader)
            receiveCurrencyViewModel?.update(cryptoAmountState: .loading)
            receiveCurrencyViewModel?.update(fiatAmountState: .loading)

        case .preview(let result):
            refreshWarningRowViewModel = nil
            feeWarningRowViewModel = nil
            swapButtonIsLoading = false

            restartTimer()
            updateReceiveCurrencyValue(value: result.expectedAmount)
            updateRequiredPermission(isPermissionRequired: result.isPermissionRequired)
            updatePendingApprovingTransaction(hasPendingTransaction: result.hasPendingTransaction)

        case .available(let result, _):
            refreshWarningRowViewModel = nil
            swapButtonIsLoading = false

            restartTimer()
            updateReceiveCurrencyValue(value: result.amount)
            updateRequiredPermission(isPermissionRequired: result.isPermissionRequired)
            updateEnoughAmountForFee(isEnoughAmountForFee: result.isEnoughAmountForFee)

        case .requiredRefresh(let error):
            swapButtonIsLoading = false

            stopTimer()
            receiveCurrencyViewModel?.update(cryptoAmountState: .loaded(0))
            receiveCurrencyViewModel?.update(fiatAmountState: .loaded(0))

            processingError(error: error)
        }
    }

    func updateReceiveCurrencyValue(value: Decimal) {
        receiveCurrencyViewModel?.update(cryptoAmountState: .loaded(value))

        guard let destination = swappingInteractor.getSwappingItems().destination else { return }
        receiveCurrencyViewModel?.update(fiatAmountState: .loading)

        Task {
            let fiatValue = try await fiatRatesProvider.getFiat(for: destination, amount: value)

            try Task.checkCancellation()

            await runOnMain {
                receiveCurrencyViewModel?.update(fiatAmountState: .loaded(fiatValue))
            }

            try Task.checkCancellation()

            try await checkForHighPriceImpact(destinationFiatAmount: fiatValue)
        }
        .store(in: &workingTasks)
    }

    func updateRequiredPermission(isPermissionRequired: Bool) {
        if isPermissionRequired {
            permissionInfoRowViewModel = DefaultWarningRowViewModel(
                title: Localization.swappingGivePermission,
                subtitle: Localization.swappingPermissionSubheader(swappingInteractor.getSwappingItems().source.symbol),
                leftView: .icon(Assets.swappingLock)
            )
        } else {
            permissionInfoRowViewModel = nil
        }
    }

    func updatePendingApprovingTransaction(hasPendingTransaction: Bool) {
        if hasPendingTransaction {
            permissionInfoRowViewModel = DefaultWarningRowViewModel(
                title: Localization.swappingPendingTransactionTitle,
                subtitle: Localization.swappingPendingTransactionSubtitle,
                leftView: .loader
            )
        } else {
            permissionInfoRowViewModel = nil
        }
    }

    func updateEnoughAmountForFee(isEnoughAmountForFee: Bool) {
        if isEnoughAmountForFee {
            feeWarningRowViewModel = nil
        } else {
            let sourceBlockchain = swappingInteractor.getSwappingItems().source.blockchain
            feeWarningRowViewModel = DefaultWarningRowViewModel(
                subtitle: Localization.swappingNotEnoughFundsForFee(sourceBlockchain.symbol, sourceBlockchain.symbol),
                leftView: .icon(Assets.attention)
            )
        }
    }

    func updateFeeValue(state: SwappingAvailabilityState) {
        switch state {
        case .idle, .requiredRefresh, .preview:
            swappingFeeRowViewModel?.update(state: .idle)
        case .loading(let type):
            if type == .full {
                swappingFeeRowViewModel?.update(state: .loading)
            }
        case .available(_, let info):
            let source = swappingInteractor.getSwappingItems().source

            Task {
                let fiatFee = try await fiatRatesProvider.getFiat(for: info.sourceBlockchain, amount: info.fee)
                let code = await AppSettings.shared.selectedCurrencyCode

                try Task.checkCancellation()

                await runOnMain {
                    swappingFeeRowViewModel?.update(
                        state: .fee(
                            fee: info.fee.groupedFormatted(),
                            symbol: source.blockchain.symbol,
                            fiat: fiatFee.currencyFormatted(code: code)
                        )
                    )
                }
            }
            .store(in: &workingTasks)
        }
    }

    func updateMainButton(state: SwappingAvailabilityState) {
        switch state {
        case .idle:
            mainButtonIsEnabled = false
            mainButtonState = .swap
        case .loading(let type):
            if type == .full {
                mainButtonIsEnabled = false
            }
        case .requiredRefresh:
            mainButtonIsEnabled = false
        case .preview(let preview):
            mainButtonIsEnabled = preview.isEnoughAmountForSwapping && !preview.hasPendingTransaction

            if !preview.isEnoughAmountForSwapping {
                mainButtonState = .insufficientFunds
            } else if preview.hasPendingTransaction {
                mainButtonState = .swap
            } else if preview.isPermissionRequired {
                mainButtonState = .givePermission
            } else {
                mainButtonState = .swap
            }

        case .available(let model, _):
            mainButtonIsEnabled = model.isEnoughAmountForSwapping && model.isEnoughAmountForFee

            if !model.isEnoughAmountForSwapping {
                mainButtonState = .insufficientFunds
            } else if model.isPermissionRequired {
                mainButtonState = .givePermission
            } else {
                mainButtonState = .swap
            }
        }
    }

    func updateRefreshWarningRowViewModel(message: String) {
        refreshWarningRowViewModel = DefaultWarningRowViewModel(
            subtitle: Localization.swappingErrorWrapper(message.capitalizingFirstLetter()),
            leftView: .icon(Assets.attention),
            rightView: .icon(Assets.refreshWarningIcon)
        ) { [weak self] in
            self?.didTapWaringRefresh()
        }
    }

    func checkForHighPriceImpact(destinationFiatAmount: Decimal) async throws {
        guard let sendDecimalValue = sendDecimalValue?.value else {
            // Current send decimal value was changed during old update. We can ignore this check
            return
        }

        if sendDecimalValue.isZero {
            // No need to calculate price impact with zero input
            await runOnMain {
                highPriceImpactWarningRowViewModel = nil
            }
            return
        }

        let sourceFiatAmount = try await fiatRatesProvider.getFiat(
            for: swappingInteractor.getSwappingItems().source,
            amount: sendDecimalValue
        )

        let lossesInPercents = (1 - destinationFiatAmount / sourceFiatAmount) * 100

        await runOnMain {
            if lossesInPercents >= Constants.highPriceImpactWarningLimit {
                highPriceImpactWarningRowViewModel = DefaultWarningRowViewModel(
                    title: Localization.swappingHighPriceImpact,
                    subtitle: Localization.swappingHighPriceImpactDescription,
                    leftView: .icon(Assets.warningIcon)
                )
            } else {
                highPriceImpactWarningRowViewModel = nil
            }
        }
    }

    func setupView() {
        updateView(swappingItems: swappingInteractor.getSwappingItems())
        swappingFeeRowViewModel = SwappingFeeRowViewModel(state: .idle) { [weak self] in
            .init {
                self?.feeInfoRowViewModel != nil
            } set: { isOpen in
                UIApplication.shared.endEditing()

                if isOpen {
                    let percentFee = self?.swappingInteractor.getReferrerAccountFee() ?? 0
                    let formattedFee = "\(percentFee.groupedFormatted())%"
                    self?.feeInfoRowViewModel = DefaultWarningRowViewModel(
                        subtitle: Localization.swappingTangemFeeDisclaimer(formattedFee),
                        leftView: .icon(Assets.heartMini)
                    )
                } else {
                    self?.feeInfoRowViewModel = nil
                }
            }
        }
    }

    func bind() {
        $sendDecimalValue
            .dropFirst()
            .removeDuplicates { $0?.value == $1?.value }
            // If value == nil then continue chain also
            .filter { $0?.isInternal ?? true }
            .handleEvents(receiveOutput: { [weak self] amount in
                self?.swappingInteractor.cancelRefresh()
                self?.updateSendFiatValue(amount: amount?.value)
                self?.stopTimer()
            })
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] amount in
                self?.resetViews()
                self?.swappingInteractor.update(amount: amount?.value)

                if let amount, amount.value > 0 {
                    self?.startTimer()
                }
            }
            .store(in: &bag)

        swappingInteractor.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateState(state: state)
            }
            .store(in: &bag)
    }

    func mapToSwappingTokenIconViewModel(currency: Currency?) -> SwappingTokenIconViewModel {
        guard let currency = currency else {
            return SwappingTokenIconViewModel(state: .loading)
        }

        switch currency.currencyType {
        case .coin:
            return SwappingTokenIconViewModel(
                state: .loaded(
                    imageURL: tokenIconURLBuilder.iconURL(id: currency.blockchain.id, size: .large),
                    symbol: currency.symbol
                )
            )
        case .token:
            return SwappingTokenIconViewModel(
                state: .loaded(
                    imageURL: tokenIconURLBuilder.iconURL(id: currency.id, size: .large),
                    networkURL: tokenIconURLBuilder.iconURL(id: currency.blockchain.id, size: .small),
                    symbol: currency.symbol
                )
            )
        }
    }
}

// MARK: - Methods

private extension SwappingViewModel {
    func update(swappingItems: SwappingItems, shouldRefresh: Bool) async {
        let updatedItems = await swappingInteractor.update(swappingItems: swappingItems)

        await runOnMain {
            updateView(swappingItems: updatedItems)
        }

        if shouldRefresh {
            swappingInteractor.refresh(type: .full)
        }
    }

    func loadDestinationIfNeeded() {
        guard swappingInteractor.getSwappingItems().destination == nil else {
            AppLog.shared.debug("Swapping item destination has already set")
            return
        }

        Task {
            var items = swappingInteractor.getSwappingItems()

            do {
                items.destination = try await swappingDestinationService.getDestination(source: items.source)
                await update(swappingItems: items, shouldRefresh: true)

            } catch {
                AppLog.shared.debug("Destination load handle error")
                AppLog.shared.error(error)
                items.destination = nil
            }
        }
        .store(in: &workingTasks)
    }

    func swapItems() {
        let state = swappingInteractor.getAvailabilityState()
        guard case .available(let result, let info) = state else {
            return
        }

        stopTimer()
        Analytics.log(
            event: .swapButtonSwap,
            params: [
                .sendToken: info.sourceCurrency.symbol,
                .receiveToken: info.destinationCurrency.symbol,
            ]
        )

        Task {
            do {
                let sendResult = try await transactionSender.sendTransaction(info)

                try Task.checkCancellation()

                addDestinationTokenToUserWalletList()
                swappingInteractor.didSendSwapTransaction(swappingTxData: info)

                Analytics.log(.transactionSent, params: [.commonSource: .transactionSourceSwap])

                await runOnMain {
                    openSuccessView(result: result, transactionData: info, transactionID: sendResult.hash)
                }
            } catch TangemSdkError.userCancelled {
                restartTimer()
            } catch {
                await runOnMain {
                    errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
                }
            }
        }
        .store(in: &workingTasks)
    }

    func processingError(error: Error) {
        AppLog.shared.debug("DefaultSwappingManager catch error: ")
        AppLog.shared.error(error)

        switch error {
        case let error as SwappingManagerError:
            switch error {
            case .walletAddressNotFound, .destinationNotFound, .amountNotFound:
                updateRefreshWarningRowViewModel(message: error.localizedDescription)
            }
        case let error as SwappingProviderError:
            switch error {
            case .requestError(let error):
                updateRefreshWarningRowViewModel(message: error.detailedError.localizedDescription)
            case .oneInchError(let error):
                updateRefreshWarningRowViewModel(message: error.localizedDescription)
            case .decodingError(let error):
                updateRefreshWarningRowViewModel(message: error.localizedDescription)
            }
        default:
            updateRefreshWarningRowViewModel(message: Localization.commonError)
        }
    }

    func addDestinationTokenToUserWalletList() {
        guard let destination = swappingInteractor.getSwappingItems().destination,
              let token = currencyMapper.mapToToken(currency: destination) else {
            return
        }

        let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: token)
        userWalletModel.append(entries: [entry])
        userWalletModel.updateWalletModels()
    }
}

// MARK: - Timer

private extension SwappingViewModel {
    func restartTimer() {
        stopTimer()
        startTimer()
    }

    func stopTimer() {
        AppLog.shared.debug("[Swap] Stop timer")
        refreshDataTimerBag?.cancel()
        refreshDataTimer
            .connect()
            .cancel()
    }

    func startTimer() {
        AppLog.shared.debug("[Swap] Start timer")
        refreshDataTimerBag = refreshDataTimer
            .autoconnect()
            .sink { [weak self] date in
                AppLog.shared.debug("[Swap] Timer call autoupdate")
                self?.swappingInteractor.refresh(type: .refreshRates)
            }
    }
}

extension SwappingViewModel {
    enum InformationSectionViewModel: Hashable, Identifiable {
        var id: Int { hashValue }

        case fee(SwappingFeeRowViewModel)
        case warning(DefaultWarningRowViewModel)
    }

    enum MainButtonState: Hashable, Identifiable {
        var id: Int { hashValue }

        case swap
        case insufficientFunds
        case givePermission
        case permitAndSwap

        var title: String {
            switch self {
            case .swap:
                return Localization.swappingSwapAction
            case .insufficientFunds:
                return Localization.swappingInsufficientFunds
            case .givePermission:
                return Localization.swappingGivePermission
            case .permitAndSwap:
                return Localization.swappingPermitAndSwap
            }
        }

        var icon: MainButton.Icon? {
            switch self {
            case .swap, .permitAndSwap:
                return .trailing(Assets.tangemIcon)
            case .givePermission, .insufficientFunds:
                return .none
            }
        }
    }
}

extension SwappingViewModel {
    private enum Constants {
        static let highPriceImpactWarningLimit: Decimal = 10
    }
}
