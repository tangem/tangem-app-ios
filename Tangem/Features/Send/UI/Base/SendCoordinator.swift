//
//  SendCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import SwiftUI
import BlockchainSdk
import TangemExpress
import TangemStaking

class SendCoordinator: CoordinatorObject {
    let dismissAction: Action<(walletModel: any WalletModel, userWalletModel: UserWalletModel)?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SendViewModel?

    // MARK: - Child coordinators

    @Published var qrScanViewCoordinator: QRScanViewCoordinator?
    @Published var onrampProvidersCoordinator: OnrampProvidersCoordinator?
    @Published var onrampCountryDetectionCoordinator: OnrampCountryDetectionCoordinator?

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?
    @Published var expressApproveViewModel: ExpressApproveViewModel?

    @Published var onrampSettingsViewModel: OnrampSettingsViewModel?
    @Published var onrampCountrySelectorViewModel: OnrampCountrySelectorViewModel?
    @Published var onrampCurrencySelectorViewModel: OnrampCurrencySelectorViewModel?
    @Published var onrampRedirectingViewModel: OnrampRedirectingViewModel?

    private var safariHandle: SafariHandle?

    required init(
        dismissAction: @escaping Action<(walletModel: any WalletModel, userWalletModel: UserWalletModel)?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let factory = SendFlowFactory(
            userWalletModel: options.userWalletModel,
            walletModel: options.walletModel,
            source: options.source
        )

        let stakingParams = StakingBlockchainParams(blockchain: options.walletModel.tokenItem.blockchain)

        switch options.type {
        case .send where FeatureProvider.isAvailable(.newSendUI):
            rootViewModel = factory.makeNewSendViewModel(router: self)
        case .send(let parameters) where parameters.nonFungibleTokenParameters != nil:
            rootViewModel = factory.makeNFTSendViewModel(parameters: parameters.nonFungibleTokenParameters!, router: self)
        case .send:
            rootViewModel = factory.makeSendViewModel(router: self)
        case .sell(let parameters):
            rootViewModel = factory.makeSellViewModel(sellParameters: parameters, router: self)
        case .staking(let manager) where stakingParams.isStakingAmountEditable:
            rootViewModel = factory.makeStakingViewModel(manager: manager, router: self)
        case .staking(let manager): // we are using restaking flow here because it doesn't allow to edit amount
            rootViewModel = factory.makeRestakingViewModel(manager: manager, router: self)
        case .unstaking(let manager, let action):
            rootViewModel = factory.makeUnstakingViewModel(manager: manager, action: action, router: self)
        case .restaking(let manager, let action):
            rootViewModel = factory.makeRestakingViewModel(manager: manager, action: action, router: self)
        case .stakingSingleAction(let manager, let action):
            rootViewModel = factory.makeStakingSingleActionViewModel(manager: manager, action: action, router: self)
        case .onramp:
            rootViewModel = factory.makeOnrampViewModel(router: self)
        }
    }
}

// MARK: - Options

extension SendCoordinator {
    struct Options {
        let walletModel: any WalletModel
        let userWalletModel: UserWalletModel
        let type: SendType
        let source: Source
    }

    enum Source {
        case main
        case tokenDetails
        case stakingDetails
        case markets
        case actionButtons
        case nft

        var analytics: Analytics.ParameterValue {
            switch self {
            case .main: .longTap
            case .tokenDetails: .token
            case .stakingDetails: .token
            case .markets: .markets
            case .actionButtons: .main
            case .nft: .nft
            }
        }
    }
}

// MARK: - SendRoutable

extension SendCoordinator: SendRoutable {
    func dismiss() {
        dismiss(with: nil)
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToSendTx)
    }

    func openFeeExplanation(url: URL) {
        safariManager.openURL(url)
    }

    func openExplorer(url: URL) {
        safariManager.openURL(url)
    }

    func openShareSheet(url: URL) {
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    func openQRScanner(with codeBinding: Binding<String>, networkName: String) {
        guard qrScanViewCoordinator == nil else {
            AppLogger.error(error: "Attempt to present multiple QR scan view coordinators")
            return
        }

        Analytics.log(.sendButtonQRCode)

        let qrScanViewCoordinator = QRScanViewCoordinator { [weak self] in
            self?.qrScanViewCoordinator = nil
        }

        let text = Localization.sendQrcodeScanInfo(networkName)
        let options = QRScanViewCoordinator.Options(code: codeBinding, text: text)
        qrScanViewCoordinator.start(with: options)

        self.qrScanViewCoordinator = qrScanViewCoordinator
    }

    func openFeeCurrency(for walletModel: any WalletModel, userWalletModel: UserWalletModel) {
        dismiss(with: (walletModel, userWalletModel))
    }

    func openApproveView(settings: ExpressApproveViewModel.Settings, approveViewModelInput: any ApproveViewModelInput) {
        expressApproveViewModel = .init(
            settings: settings,
            feeFormatter: CommonFeeFormatter(
                balanceFormatter: .init(),
                balanceConverter: .init()
            ),
            approveViewModelInput: approveViewModelInput,
            coordinator: self
        )
    }
}

// MARK: - OnrampRoutable

extension SendCoordinator: OnrampRoutable {
    func openOnrampCountryDetection(country: OnrampCountry, repository: OnrampRepository, dataRepository: OnrampDataRepository) {
        let coordinator = OnrampCountryDetectionCoordinator(dismissAction: { [weak self] option in
            switch option {
            case .none:
                self?.onrampCountryDetectionCoordinator = nil
            case .closeOnramp:
                if #available(iOS 16, *) {
                    self?.dismiss(with: nil)
                } else {
                    // On iOS 15 double dismiss doesn't work
                    self?.onrampCountryDetectionCoordinator = nil

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.dismiss(with: nil)
                    }
                }
            }
        })

        coordinator.start(with: .init(country: country, repository: repository, dataRepository: dataRepository))
        onrampCountryDetectionCoordinator = coordinator
    }

    func openOnrampCountrySelector(repository: any OnrampRepository, dataRepository: any OnrampDataRepository) {
        onrampCountrySelectorViewModel = OnrampCountrySelectorViewModel(
            repository: repository,
            dataRepository: dataRepository,
            coordinator: self
        )
    }

    func openOnrampSettings(repository: any OnrampRepository) {
        onrampSettingsViewModel = OnrampSettingsViewModel(
            repository: repository,
            coordinator: self
        )
    }

    func openOnrampCurrencySelector(repository: any OnrampRepository, dataRepository: any OnrampDataRepository) {
        onrampCurrencySelectorViewModel = OnrampCurrencySelectorViewModel(
            repository: repository,
            dataRepository: dataRepository,
            coordinator: self
        )
    }

    func openOnrampProviders(providersBuilder: OnrampProvidersBuilder, paymentMethodsBuilder: OnrampPaymentMethodsBuilder) {
        let coordinator = OnrampProvidersCoordinator(
            onrampProvidersBuilder: providersBuilder,
            onrampPaymentMethodsBuilder: paymentMethodsBuilder,
            dismissAction: { [weak self] in
                self?.onrampProvidersCoordinator = nil
            }, popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)
        onrampProvidersCoordinator = coordinator
    }

    func openOnrampRedirecting(onrampRedirectingBuilder: OnrampRedirectingBuilder) {
        onrampRedirectingViewModel = onrampRedirectingBuilder.makeOnrampRedirectingViewModel(coordinator: self)
    }

    func openOnrampWebView(url: URL, onDismiss: @escaping () -> Void, onSuccess: @escaping (URL) -> Void) {
        safariHandle = safariManager.openURL(url, configuration: .init(), onDismiss: onDismiss, onSuccess: { [weak self] url in
            self?.safariHandle = nil
            onSuccess(url)
        })

        dismissOnrampRedirecting()
    }
}

// MARK: - ExpressApproveRoutable

extension SendCoordinator: ExpressApproveRoutable {
    func didSendApproveTransaction() {
        expressApproveViewModel = nil
    }

    func userDidCancel() {
        expressApproveViewModel = nil
    }
}

// MARK: - OnrampCountrySelectorRoutable

extension SendCoordinator: OnrampCountrySelectorRoutable {
    func dismissCountrySelector() {
        onrampCountrySelectorViewModel = nil
    }
}

// MARK: - OnrampSettingsRoutable

extension SendCoordinator: OnrampSettingsRoutable {
    func openOnrampCountrySelector() {
        rootViewModel?.openOnrampCountrySelectorView()
    }
}

// MARK: - OnrampCurrencySelectorRoutable

extension SendCoordinator: OnrampCurrencySelectorRoutable {
    func dismissCurrencySelector() {
        onrampCurrencySelectorViewModel = nil
    }
}

// MARK: - OnrampAmountRoutable

extension SendCoordinator: OnrampAmountRoutable {
    func openOnrampCurrencySelector() {
        rootViewModel?.openOnrampCurrencySelectorView()
    }
}

// MARK: - OnrampRedirectingRoutable

extension SendCoordinator: OnrampRedirectingRoutable {
    func dismissOnrampRedirecting() {
        onrampRedirectingViewModel = nil
    }
}
