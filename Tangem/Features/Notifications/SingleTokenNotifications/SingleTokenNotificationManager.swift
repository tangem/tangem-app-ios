//
//  SingleWalletNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk
import TangemStaking
import TangemFoundation

final class SingleTokenNotificationManager {
    weak var interactionDelegate: SingleTokenNotificationManagerInteractionDelegate?

    private let analyticsService: NotificationsAnalyticsService = .init()

    private let walletModel: any WalletModel
    private let walletModelsManager: WalletModelsManager
    private weak var delegate: NotificationTapDelegate?

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    private var rentFeeNotification: NotificationViewInput?
    private var bag: Set<AnyCancellable> = []
    private var notificationsUpdateTask: Task<Void, Never>?

    init(
        walletModel: any WalletModel,
        walletModelsManager: WalletModelsManager,
        contextDataProvider: AnalyticsContextDataProvider?
    ) {
        self.walletModel = walletModel
        self.walletModelsManager = walletModelsManager

        analyticsService.setup(with: self, contextDataProvider: contextDataProvider)
    }

    private func bind() {
        bag = []

        Publishers.CombineLatest(
            walletModel.availableBalanceProvider.balanceTypePublisher,
            walletModel.totalTokenBalanceProvider.balanceTypePublisher
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] availableState, totalState in
            self?.notificationsUpdateTask?.cancel()

            switch (availableState, totalState) {
            case (.failure(.none), _):
                self?.setupNetworkUnreachable()
            case (_, .failure(.some(let cached))):
                self?.setupNetworkNotUpdated(lastUpdatedDate: cached.date)
            case (_, .empty(.noAccount(let message))):
                self?.setupNoAccountNotification(with: message)
            case (_, .loaded):
                self?.setupLoadedStateNotifications()
            default:
                break
            }
        }
        .store(in: &bag)
    }

    private func setupLoadedStateNotifications() {
        let factory = NotificationsFactory()

        var events = [TokenNotificationEvent]()

        if let event = makeStakingNotificationEvent() {
            events.append(event)
        }

        if let existentialWarning = walletModel.existentialDepositWarning {
            events.append(.existentialDepositWarning(message: existentialWarning))
        }

        if let feeResourceInfoProvider = walletModel as? FeeResourceInfoProvider,
           let currentResource = feeResourceInfoProvider.feeResourceBalance,
           let maxResource = feeResourceInfoProvider.maxResourceBalance {
            let formatter = BalanceFormatter()

            switch walletModel.tokenItem.blockchain {
            case .koinos:
                events.append(
                    .manaLevel(
                        currentMana: formatter.formatDecimal(currentResource, formattingOptions: .defaultFiatFormattingOptions),
                        maxMana: formatter.formatDecimal(maxResource, formattingOptions: .defaultFiatFormattingOptions)
                    )
                )
            default:
                break
            }
        }

        // We can't use `Blockchain.polygon(testnet: false).currencySymbol` here
        // because it will be changed after some time to `"POL"`
        // [REDACTED_TODO_COMMENT]
        if walletModel.tokenItem.currencySymbol == CurrencySymbol.matic,
           walletModel.tokenItem.isToken,
           walletModel.tokenItem.networkId != Blockchain.polygon(testnet: false).networkId {
            events.append(.maticMigration)
        }

        if let sendingRestrictions = walletModel.sendingRestrictions {
            let isFeeCurrencyPurchaseAllowed = walletModelsManager.walletModels.contains {
                $0.tokenItem == walletModel.feeTokenItem && $0.tokenItem.blockchainNetwork == walletModel.tokenItem.blockchainNetwork
            }

            if let event = TokenNotificationEvent.event(for: sendingRestrictions, isFeeCurrencyPurchaseAllowed: isFeeCurrencyPurchaseAllowed) {
                events.append(event)
            }
        }

        // YIELD TODO
        if false {
            events.append(makeYieldAvailableNotification())
        }

        events += makeAssetRequirementsNotificationEvents()

        let inputs = events.map {
            factory.buildNotificationInput(
                for: $0,
                buttonAction: { [weak self] id, actionType in
                    self?.delegate?.didTapNotification(with: id, action: actionType)
                },
                dismissAction: { [weak self] id in
                    self?.dismissNotification(with: id)
                }
            )
        }

        notificationInputsSubject.send(inputs)

        setupRentFeeNotification()
    }

    private func setupRentFeeNotification() {
        if let rentFeeNotification {
            notificationInputsSubject.value.append(rentFeeNotification)
        }

        notificationsUpdateTask?.cancel()
        notificationsUpdateTask = Task { [weak self] in
            guard
                let rentInput = await self?.loadRentNotificationIfNeeded(),
                let self
            else {
                return
            }

            if Task.isCancelled {
                return
            }

            if !notificationInputsSubject.value.contains(where: { $0.id == rentInput.id }) {
                await runOnMain {
                    self.rentFeeNotification = rentInput
                    self.notificationInputsSubject.value.append(rentInput)
                }
            }
        }
    }

    private func setupNetworkUnreachable() {
        let factory = NotificationsFactory()

        if case .binance = walletModel.tokenItem.blockchain {
            notificationInputsSubject.send([
                factory.buildNotificationInput(for: TokenNotificationEvent.bnbBeaconChainRetirement),
            ])
        } else {
            notificationInputsSubject
                .send([
                    factory.buildNotificationInput(
                        for: TokenNotificationEvent.networkUnreachable(currencySymbol: walletModel.tokenItem.blockchain.currencySymbol),
                        dismissAction: weakify(self, forFunction: SingleTokenNotificationManager.dismissNotification(with:))
                    ),
                ])
        }
    }

    private func setupNetworkNotUpdated(lastUpdatedDate: Date) {
        notificationInputsSubject.send([
            NotificationsFactory().buildNotificationInput(
                for: TokenNotificationEvent.networkNotUpdated(lastUpdatedDate: lastUpdatedDate)
            ),
        ])
    }

    private func setupNoAccountNotification(with message: String) {
        // Skip displaying the BEP2 account creation top-up notification
        // since it will be deprecated shortly due to the network shutdown
        if case .binance = walletModel.tokenItem.blockchain {
            return
        }

        let factory = NotificationsFactory()
        let event = TokenNotificationEvent.noAccount(message: message)

        notificationInputsSubject
            .send([
                factory.buildNotificationInput(
                    for: event,
                    buttonAction: { [weak self] id, actionType in
                        self?.delegate?.didTapNotification(with: id, action: actionType)
                    },
                    dismissAction: { [weak self] id in
                        self?.dismissNotification(with: id)
                    }
                ),
            ])
    }

    private func loadRentNotificationIfNeeded() async -> NotificationViewInput? {
        guard walletModel.hasRent else { return nil }

        guard let rentMessage = try? await walletModel.updateRentWarning().async() else {
            return nil
        }

        if Task.isCancelled {
            return nil
        }

        let factory = NotificationsFactory()
        let input = factory.buildNotificationInput(
            for: TokenNotificationEvent.rentFee(rentMessage: rentMessage),
            dismissAction: weakify(self, forFunction: SingleTokenNotificationManager.dismissNotification(with:))
        )
        return input
    }

    private func makeAssetRequirementsNotificationEvents() -> [TokenNotificationEvent] {
        let asset = walletModel.tokenItem.amountType

        guard
            !walletModel.hasPendingTransactions,
            let assetRequirementsManager = walletModel.assetRequirementsManager
        else {
            return []
        }

        switch assetRequirementsManager.requirementsCondition(for: asset) {
        case .requiresTrustline(let blockchain, let fee, let isProcessingTrustlineOperation):
            let configuration = makeUnfulfilledRequirementsConfiguration(
                blockchain: blockchain,
                transactionAmount: nil,
                feeAmount: fee,
                isProcessingFulfillRequirementOperation: isProcessingTrustlineOperation
            )

            return [.hasUnfulfilledRequirements(configuration: configuration)]

        case .paidTransactionWithFee(let blockchain, let transactionAmount, let feeAmount):
            let configuration = makeUnfulfilledRequirementsConfiguration(
                blockchain: blockchain,
                transactionAmount: transactionAmount,
                feeAmount: feeAmount
            )
            return [.hasUnfulfilledRequirements(configuration: configuration)]

        case .none:
            return []
        }
    }

    private func makeUnfulfilledRequirementsConfiguration(
        blockchain: Blockchain,
        transactionAmount: Amount?,
        feeAmount: Amount?,
        isProcessingFulfillRequirementOperation: Bool? = nil
    ) -> TokenNotificationEvent.UnfulfilledRequirementsConfiguration {
        switch blockchain {
        case .stellar, .xrp:
            let formattedReserve = BalanceFormatter().formatDecimal(feeAmount?.value, formattingOptions: .defaultCryptoFeeFormattingOptions)
            return .missingTokenTrustline(
                .init(
                    reserveCurrencySymbol: blockchain.currencySymbol,
                    reserveAmount: formattedReserve,
                    icon: NetworkImageProvider().provide(by: blockchain, filled: true),
                    trustlineOperationInProgress: isProcessingFulfillRequirementOperation ?? false
                )
            )

        case .hedera:
            guard let feeAmount else {
                return .missingHederaTokenAssociation(associationFee: nil)
            }

            let configurationData = makeRequirementsConfigurationData(from: feeAmount)

            return .missingHederaTokenAssociation(
                associationFee: .init(
                    formattedValue: configurationData.formattedValue,
                    currencySymbol: configurationData.currencySymbol
                )
            )

        case .kaspa:
            guard let transactionAmount else {
                preconditionFailure("Tx amount is required for making unfulfilled requirements configuration for blockchain '\(blockchain.displayName)'")
            }

            let configurationData = makeRequirementsConfigurationData(from: transactionAmount)
            let asset = transactionAmount.type

            return .incompleteKaspaTokenTransaction(
                revealTransaction: .init(
                    formattedValue: configurationData.formattedValue,
                    currencySymbol: configurationData.currencySymbol,
                    blockchainName: blockchain.displayName
                ) { [weak walletModel] in
                    walletModel?.assetRequirementsManager?.discardRequirements(for: asset)
                }
            )

        default:
            preconditionFailure("Unsupported blockchain '\(blockchain.displayName)', can't create unfulfilled requirements configuration")
        }
    }

    private func makeRequirementsConfigurationData(
        from amount: Amount
    ) -> (formattedValue: String, currencySymbol: String) {
        let balanceFormatter = BalanceFormatter()
        let formattedValue = balanceFormatter.formatDecimal(amount.value)

        return (formattedValue, amount.currencySymbol)
    }

    func makeStakingNotificationEvent() -> TokenNotificationEvent? {
        guard case .availableToStake(let yield) = walletModel.stakingManagerState else {
            return nil
        }

        let tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
        let apyFormatted = PercentFormatter().format(yield.rewardRateValues.max, option: .staking)

        return .staking(tokenIconInfo: tokenIconInfo, earnUpToFormatted: apyFormatted)
    }

    private func hideNotification(_ notification: NotificationViewInput) {
        notificationInputsSubject.value.removeAll { $0 == notification }
    }

    private func makeYieldAvailableNotification() -> TokenNotificationEvent {
        .yieldAvailable(configuration: .init(yieldRate: "5.1"))
    }
}

extension SingleTokenNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate

        setupLoadedStateNotifications()
        bind()
    }

    func dismissNotification(with id: NotificationViewId) {
        guard let notification = notificationInputsSubject.value.first(where: { $0.id == id }) else {
            return
        }

        if let event = notification.settings.event as? TokenNotificationEvent {
            switch event {
            case .hasUnfulfilledRequirements(.incompleteKaspaTokenTransaction(let revealTransaction)):
                Analytics.log(event: .tokenButtonRevealCancel, params: event.analyticsParams)

                interactionDelegate?.confirmDiscardingUnfulfilledAssetRequirements(
                    with: .incompleteKaspaTokenTransaction(revealTransaction: revealTransaction),
                    confirmationAction: { [weak self] in
                        revealTransaction.onTransactionDiscard()
                        self?.hideNotification(notification)
                    }
                )
                // Early exit since `hideNotification(_:)` is called inside `confirmationAction` callback
                return
            default:
                break
            }
        }

        hideNotification(notification)
    }
}

// MARK: - Constants

private extension SingleTokenNotificationManager {
    enum CurrencySymbol {
        static let matic = "MATIC"
    }
}
