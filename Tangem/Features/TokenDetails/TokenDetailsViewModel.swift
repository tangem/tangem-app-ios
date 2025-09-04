//
//  TokenDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk
import TangemExpress
import TangemStaking
import TangemFoundation
import TangemLocalization
import TangemUI
import struct TangemUIUtils.ActionSheetBinder
import BigInt

final class TokenDetailsViewModel: SingleTokenBaseViewModel, ObservableObject {
    @Published var actionSheet: ActionSheetBinder?
    @Published var bannerNotificationInputs: [NotificationViewInput] = []

    private(set) lazy var balanceWithButtonsModel = BalanceWithButtonsViewModel(
        buttonsPublisher: $actionButtons.eraseToAnyPublisher(),
        balanceProvider: self,
        balanceTypeSelectorProvider: self
    )

    private(set) lazy var tokenDetailsHeaderModel: TokenDetailsHeaderViewModel = .init(tokenItem: walletModel.tokenItem)
    @Published private(set) var activeStakingViewData: ActiveStakingViewData?

    private weak var coordinator: TokenDetailsRoutable?
    private let bannerNotificationManager: NotificationManager?
    private let xpubGenerator: XPUBGenerator?
    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()
    private let pendingTransactionDetails: PendingTransactionDetails?
    private var bag = Set<AnyCancellable>()

    var iconUrl: URL? {
        guard let id = walletModel.tokenItem.id else {
            return nil
        }

        return IconURLBuilder().tokenIconURL(id: id)
    }

    var customTokenColor: Color? {
        walletModel.tokenItem.token?.customTokenColor
    }

    var canHideToken: Bool { userWalletModel.config.hasFeature(.multiCurrency) }

    var canGenerateXPUB: Bool { xpubGenerator != nil }

    var hasDotsMenu: Bool { canHideToken || canGenerateXPUB }

    init(
        userWalletModel: UserWalletModel,
        walletModel: any WalletModel,
        notificationManager: NotificationManager,
        bannerNotificationManager: NotificationManager?,
        pendingExpressTransactionsManager: PendingExpressTransactionsManager,
        xpubGenerator: XPUBGenerator?,
        coordinator: TokenDetailsRoutable,
        tokenRouter: SingleTokenRoutable,
        pendingTransactionDetails: PendingTransactionDetails?
    ) {
        self.coordinator = coordinator
        self.bannerNotificationManager = bannerNotificationManager
        self.xpubGenerator = xpubGenerator
        self.pendingTransactionDetails = pendingTransactionDetails

        super.init(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            notificationManager: notificationManager,
            pendingExpressTransactionsManager: pendingExpressTransactionsManager,
            tokenRouter: tokenRouter
        )
        notificationManager.setupManager(with: self)
        bannerNotificationManager?.setupManager(with: self)

        prepareSelf()
    }

    deinit {
        AppLogger.debug("TokenDetailsViewModel deinit")
    }

    func onAppear() {
        let balanceState: Analytics.ParameterValue = switch walletModel.availableBalanceProvider.balanceType {
        case .empty:
            .empty
        case .loading:
            .loading
        case .failure:
            .error
        case .loaded(let amount) where amount == .zero:
            .empty
        case .loaded:
            .full
        }

        let params: [Analytics.ParameterKey: String] = [
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.tokenItem.blockchain.displayName,
            .balance: balanceState.rawValue,
        ]

        Analytics.log(event: .detailsScreenOpened, params: params)
    }

    override func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .empty,
             .unlock:
            break
        case .openFeeCurrency:
            openFeeCurrency()
        case .swap:
            openExchange()
        case .generateAddresses,
             .backupCard,
             .buyCrypto,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountBy,
             .reduceAmountTo,
             .addHederaTokenAssociation,
             .retryKaspaTokenTransaction,
             .leaveAmount,
             .openLink,
             .stake,
             .openFeedbackMail,
             .openAppStoreReview,
             .support,
             .openCurrency,
             .seedSupportNo,
             .seedSupportYes,
             .seedSupport2No,
             .seedSupport2Yes,
             .openReferralProgram,
             .addTokenTrustline,
             .openMobileFinishActivation,
             .openMobileUpgrade:
            super.didTapNotification(with: id, action: action)
        }
    }

    override func presentActionSheet(_ actionSheet: ActionSheetBinder) {
        self.actionSheet = actionSheet
    }

    override func copyDefaultAddress() {
        super.copyDefaultAddress()
        Analytics.log(event: .buttonCopyAddress, params: [
            .token: walletModel.tokenItem.currencySymbol,
            .source: Analytics.ParameterValue.token.rawValue,
        ])
        Toast(view: SuccessToast(text: Localization.walletNotificationAddressCopied))
            .present(
                layout: .bottom(padding: 80),
                type: .temporary()
            )
    }

    override func openMarketsTokenDetails() {
        guard isMarketsDetailsAvailable else {
            return
        }

        let analyticsParams: [Analytics.ParameterKey: String] = [
            .source: Analytics.ParameterValue.token.rawValue,
            .token: walletModel.tokenItem.currencySymbol.uppercased(),
            .blockchain: walletModel.tokenItem.blockchain.displayName,
        ]
        Analytics.log(event: .marketsChartScreenOpened, params: analyticsParams)
        super.openMarketsTokenDetails()
    }
}

// MARK: - Hide token

extension TokenDetailsViewModel {
    func hideTokenButtonAction() {
        if userWalletModel.userTokensManager.canRemove(walletModel.tokenItem) {
            showHideWarningAlert()
        } else {
            showUnableToHideAlert()
        }
    }

    func generateXPUBButtonAction() {
        guard case .token(let token, _) = walletModel.tokenItem, let yieldService = walletModel.yieldService else {
            return
        }

        guard let balance = walletModel.totalTokenBalanceProvider.balanceType.value else {
            return
        }

        Task {
            do {
                let info = try await yieldService.getYieldBalanceInfo(for: walletModel.defaultAddressString, contractAddress: token.contractAddress)
                switch info.state {
                case .notDeployed:
                    do {
                        let result = try await deploy(token: token, contractAddress: token.contractAddress)
                        print(result)
                    } catch {
                        print(error)
                    }
                case .notInitialized(let yieldToken):
                    do {
                        let result = try await initToken(token: token, yieldToken: yieldToken)
                        print(result)
                    } catch {
                        print(error)
                    }
                case .initialized(.notActive):
                    // reactivate
                    break
                case .initialized(.active(let activeState)):
                    if activeState.hasActiveYield {
                        do {
                            let result = try await exit(activeState: activeState, contractAddress: token.contractAddress)
                            print(result)
                        } catch {
                            print(error)
                        }
                    } else {
                        let allowanceChecker = AllowanceChecker(
                            blockchain: blockchain,
                            amountType: walletModel.tokenItem.amountType,
                            walletAddress: walletModel.defaultAddressString,
                            ethereumNetworkProvider: walletModel.ethereumNetworkProvider,
                            ethereumTransactionDataBuilder: walletModel.ethereumTransactionDataBuilder
                        )

                        let isPermissionRequired = try await allowanceChecker.isPermissionRequired(
                            amount: balance * token.decimalValue,
                            spender: activeState.yieldToken
                        )

                        if isPermissionRequired {
                            do {
                                let approveData = try await allowanceChecker.makeApproveData(
                                    spender: activeState.yieldToken,
                                    amount: .greatestFiniteMagnitude,
                                    policy: .unlimited
                                )

                                let approve = try await requestPermissions(
                                    activeState: activeState,
                                    approveData: approveData
                                )
                                print(approve)
                            } catch {
                                print(error)
                            }
                        }
                        do {
                            let result = try await enter(
                                activeState: activeState,
                                contractAddress: token.contractAddress
                            )
                            print(result)
                        } catch {
                            print(error)
                        }
                    }
                }
                print(info)
            } catch {
                print(error)
            }
//        guard let xpubGenerator else { return }
//
//        runTask { [weak self] in
//            do {
//                let xpub = try await xpubGenerator.generateXPUB()
//                let viewController = await UIActivityViewController(activityItems: [xpub], applicationActivities: nil)
//                AppPresenter.shared.show(viewController)
//            } catch {
//                let sdkError = error.toTangemSdkError()
//                if !sdkError.isUserCancelled {
//                    self?.alert = error.alertBinder
//                }
//            }
        }
    }

    private func requestPermissions(
        activeState: YieldBalanceInfo.ActiveStateInfo,
        approveData: ApproveTransactionData
    ) async throws -> String {
        let transaction = try await walletModel.transactionCreator.buildTransaction(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            amount: 0,
            fee: approveData.fee,
            destination: .contractCall(contract: approveData.toContractAddress, data: approveData.txData)
        )

        let transactionDispatcher = TransactionDispatcherFactory(
            walletModel: walletModel,
            signer: userWalletModel.signer
        ).makeSendDispatcher()

        return try await transactionDispatcher.send(transaction: .transfer(transaction)).hash
    }

    private func initToken(token: Token, yieldToken: String) async throws -> String {
        let amount = Amount(with: walletModel.tokenItem.blockchain, type: .coin, value: 0)

        let smartContract = InitYieldTokenMethod(
            yieldTokenAddress: token.contractAddress,
            maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee * walletModel.tokenItem.blockchain.decimalValue)!
        )

        let fees = try await walletModel.ethereumNetworkProvider?.getFee(
            destination: yieldToken,
            value: amount.encodedForSend,
            data: smartContract.data
        ).async()

        guard let fee = fees?.first else {
            throw BlockchainSdkError.networkUnavailable
        }

        let transaction = try await walletModel.transactionCreator.buildTransaction(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            amount: 0,
            fee: fee,
            destination: .contractCall(contract: yieldToken, data: smartContract.data)
        )

        let transactionDispatcher = TransactionDispatcherFactory(
            walletModel: walletModel,
            signer: userWalletModel.signer
        ).makeSendDispatcher()

        return try await transactionDispatcher.send(transaction: .transfer(transaction)).hash
    }

    private func deploy(token: Token, contractAddress: String) async throws -> String {
        let amount = Amount(with: walletModel.tokenItem.blockchain, type: .coin, value: 0)

        let smartContract = DeployYieldModuleMethod(
            sourceAddress: walletModel.defaultAddressString,
            tokenAddress: contractAddress,
            maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee * walletModel.tokenItem.blockchain.decimalValue)!
        )

        let fees = try await walletModel.ethereumNetworkProvider?.getFee(
            destination: YieldConstants.yieldModuleFactoryContractAddress,
            value: amount.encodedForSend,
            data: smartContract.data
        ).async()

        guard let fee = fees?.first else {
            throw BlockchainSdkError.networkUnavailable
        }

        let transaction = try await walletModel.transactionCreator.buildTransaction(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            amount: 0,
            fee: fee,
            destination: .contractCall(contract: YieldConstants.yieldModuleFactoryContractAddress, data: smartContract.data)
        )

        let transactionDispatcher = TransactionDispatcherFactory(
            walletModel: walletModel,
            signer: userWalletModel.signer
        ).makeSendDispatcher()

        return try await transactionDispatcher.send(transaction: .transfer(transaction)).hash
    }

    private func enter(
        activeState: YieldBalanceInfo.ActiveStateInfo,
        contractAddress: String
    ) async throws -> String {
        let amount = Amount(with: walletModel.tokenItem.blockchain, type: .coin, value: 0)

        let enterAction = EnterProtocolMethod(
            yieldTokenAddress: contractAddress
        )

        let fees = try await walletModel.ethereumNetworkProvider?.getFee(
            destination: activeState.yieldToken,
            value: amount.encodedForSend,
            data: enterAction.data
        ).async()

        guard let fee = fees?.first else {
            throw BlockchainSdkError.networkUnavailable
        }

        let transaction = try await walletModel.transactionCreator.buildTransaction(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            amount: 0,
            fee: fee,
            destination: .contractCall(contract: activeState.yieldToken, data: enterAction.data)
        )

        let transactionDispatcher = TransactionDispatcherFactory(
            walletModel: walletModel,
            signer: userWalletModel.signer
        ).makeSendDispatcher()

        return try await transactionDispatcher.send(transaction: .transfer(transaction)).hash
    }

    private func exit(
        activeState: YieldBalanceInfo.ActiveStateInfo,
        contractAddress: String
    ) async throws -> String {
        let amount = Amount(with: walletModel.tokenItem.blockchain, type: .coin, value: 0)

        let enterAction = WithdrawAndDeactivateMethod(
            yieldTokenAddress: contractAddress
        )

        let fees = try await walletModel.ethereumNetworkProvider?.getFee(
            destination: activeState.yieldToken,
            value: amount.encodedForSend,
            data: enterAction.data
        ).async()

        guard let fee = fees?.first else {
            throw BlockchainSdkError.networkUnavailable
        }

        let transaction = try await walletModel.transactionCreator.buildTransaction(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            amount: 0,
            fee: fee,
            destination: .contractCall(contract: activeState.yieldToken, data: enterAction.data)
        )

        let transactionDispatcher = TransactionDispatcherFactory(
            walletModel: walletModel,
            signer: userWalletModel.signer
        ).makeSendDispatcher()

        return try await transactionDispatcher.send(transaction: .transfer(transaction)).hash
    }

    private func showUnableToHideAlert() {
        let tokenName = walletModel.tokenItem.name
        let message = Localization.tokenDetailsUnableHideAlertMessage(
            tokenName,
            currencySymbol,
            blockchain.displayName
        )

        alert = AlertBuilder.makeAlert(
            title: Localization.tokenDetailsUnableHideAlertTitle(tokenName),
            message: message,
            primaryButton: .default(Text(Localization.commonOk))
        )
    }

    private func showHideWarningAlert() {
        alert = AlertBuilder.makeAlert(
            title: Localization.tokenDetailsHideAlertTitle(walletModel.tokenItem.name),
            message: Localization.tokenDetailsHideAlertMessage,
            primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide)) { [weak self] in
                self?.hideToken()
            },
            secondaryButton: .cancel()
        )
    }

    private func hideToken() {
        Analytics.log(
            event: .buttonRemoveToken,
            params: [
                Analytics.ParameterKey.token: currencySymbol,
                Analytics.ParameterKey.source: Analytics.ParameterValue.token.rawValue,
            ]
        )

        userWalletModel.userTokensManager.remove(walletModel.tokenItem)
        dismiss()
    }
}

// MARK: - Setup functions

private extension TokenDetailsViewModel {
    private func prepareSelf() {
        tokenNotificationInputs = notificationManager.notificationInputs
        bind()
    }

    private func bind() {
        // If a pending transaction was provided for deeplink-based presentation,
        // wait for the first non-empty list of pending transactions,
        // and if it contains a transaction matching the provided ID, present its status.
        if let pendingTransactionDetails {
            $pendingExpressTransactions
                .filter { !$0.isEmpty }
                .prefix(1)
                .sink { [weak self] pendingTransactions in
                    guard let self,
                          let matchingTransaction = pendingTransactions.first(where: { $0.id == pendingTransactionDetails.id })
                    else {
                        return
                    }

                    didTapPendingExpressTransaction(id: matchingTransaction.id)
                }
                .store(in: &bag)
        }

        bannerNotificationManager?.notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.bannerNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        walletModel.stakingManagerStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                AppLogger.info("Token details receive new StakingManager state: \(state)")
                self?.updateStaking(state: state)
            }
            .store(in: &bag)
    }

    private func updateStaking(state: StakingManagerState) {
        switch state {
        case .loading:
            // Do nothing
            break
        case .availableToStake, .notEnabled:
            activeStakingViewData = nil
        case .loadingError, .temporaryUnavailable:
            activeStakingViewData = .init(balance: .loadingError, rewards: .none)
        case .staked(let staked):
            let rewards = mapToRewardsState(staked: staked)
            let balance = mapToStakedBalance(staked: staked)

            activeStakingViewData = ActiveStakingViewData(
                balance: .balance(balance) { [weak self] in self?.openStaking() },
                rewards: rewards
            )
        }
    }

    func mapToRewardsState(staked: StakingManagerState.Staked) -> ActiveStakingViewData.RewardsState? {
        switch (staked.yieldInfo.rewardClaimingType, staked.balances.rewards().sum()) {
        case (.auto, _):
            return nil
        case (.manual, .zero):
            return .noRewards
        case (.manual, let rewards):
            let stakedRewardsFiat: Decimal? = walletModel.tokenItem.currencyId.flatMap { currencyId in
                balanceConverter.convertToFiat(rewards, currencyId: currencyId)
            }
            let formatted = balanceFormatter.formatFiatBalance(stakedRewardsFiat)
            return .rewardsToClaim(formatted)
        }
    }

    func mapToStakedBalance(staked: StakingManagerState.Staked) -> BalanceFormatted {
        let stakedWithPendingBalance = staked.balances.stakes().sum()
        let stakedWithPendingBalanceFormatted = balanceFormatter.formatCryptoBalance(stakedWithPendingBalance, currencyCode: walletModel.tokenItem.currencySymbol)

        let stakedWithPendingFiatBalance = walletModel.tokenItem.currencyId.flatMap { currencyId in
            balanceConverter.convertToFiat(stakedWithPendingBalance, currencyId: currencyId)
        }
        let stakedWithPendingFiatBalanceFormatted = balanceFormatter.formatFiatBalance(stakedWithPendingFiatBalance)

        return .init(
            crypto: stakedWithPendingBalanceFormatted,
            fiat: stakedWithPendingFiatBalanceFormatted
        )
    }
}

// MARK: - Navigation functions

private extension TokenDetailsViewModel {
    func dismiss() {
        coordinator?.dismiss()
    }

    func openFeeCurrency() {
        guard let feeCurrencyWalletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
            $0.tokenItem == walletModel.feeTokenItem
        }) else {
            assertionFailure("Fee currency '\(walletModel.feeTokenItem.name)' for currency '\(walletModel.tokenItem.name)' not found")
            return
        }

        coordinator?.openFeeCurrency(for: feeCurrencyWalletModel, userWalletModel: userWalletModel)
    }
}

// MARK: - SingleTokenNotificationManagerInteractionDelegate

extension TokenDetailsViewModel: SingleTokenNotificationManagerInteractionDelegate {
    func confirmDiscardingUnfulfilledAssetRequirements(
        with configuration: TokenNotificationEvent.UnfulfilledRequirementsConfiguration,
        confirmationAction: @escaping () -> Void
    ) {
        let alertBuilder = AssetRequirementsAlertBuilder()
        alert = alertBuilder.fulfillAssetRequirementsDiscardedAlert(confirmationAction: confirmationAction)
    }
}

// MARK: - BalanceWithButtonsViewModelBalanceProvider

extension TokenDetailsViewModel: BalanceWithButtonsViewModelBalanceProvider {
    var totalCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        walletModel
            .totalTokenBalanceProvider
            .formattedBalanceTypePublisher
    }

    var totalFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        walletModel
            .fiatTotalTokenBalanceProvider
            .formattedBalanceTypePublisher
    }

    var availableCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        walletModel
            .availableBalanceProvider
            .formattedBalanceTypePublisher
    }

    var availableFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        walletModel
            .fiatAvailableBalanceProvider
            .formattedBalanceTypePublisher
    }
}

extension TokenDetailsViewModel: BalanceTypeSelectorProvider {
    var shouldShowBalanceSelector: Bool {
        switch walletModel.stakingBalanceProvider.balanceType {
        case .empty:
            return false
        case .loaded(let amount) where amount == .zero:
            return false
        case .failure(let cached) where cached?.balance == .zero || cached == nil:
            return false
        case .failure, .loading, .loaded:
            return true
        }
    }
}
