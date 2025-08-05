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
import TangemUIUtils

class SendCoordinator: CoordinatorObject {
    enum DismissOptions {
        case openFeeCurrency(walletModel: any WalletModel, userWalletModel: UserWalletModel)
        case closeButtonTap
    }

    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SendViewModel?

    // MARK: - Child coordinators

    @Published var qrScanViewCoordinator: QRScanViewCoordinator?
    @Published var onrampProvidersCoordinator: OnrampProvidersCoordinator?
    @Published var onrampCountryDetectionCoordinator: OnrampCountryDetectionCoordinator?
    @Published var sendReceiveTokenCoordinator: SendReceiveTokenCoordinator?

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?
    @Published var expressApproveViewModel: ExpressApproveViewModel?

    @Published var onrampSettingsViewModel: OnrampSettingsViewModel?
    @Published var onrampCountrySelectorViewModel: OnrampCountrySelectorViewModel?
    @Published var onrampCurrencySelectorViewModel: OnrampCurrencySelectorViewModel?
    @Published var onrampRedirectingViewModel: OnrampRedirectingViewModel?

    private var safariHandle: SafariHandle?

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
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

    private func mapDismissReasonToDismissOptions(_ reason: SendDismissReason) -> DismissOptions? {
        switch reason {
        case .mainButtonTap(type: .close):
            return .closeButtonTap
        case .mainButtonTap,
             .other:
            return nil
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

// MARK: - SendFeeRoutable

extension SendCoordinator: SendFeeRoutable {
    func openFeeExplanation(url: URL) {
        safariManager.openURL(url)
    }
}

// MARK: - SendDestinationRoutable

extension SendCoordinator: SendDestinationRoutable {
    func openQRScanner(with codeBinding: Binding<String>, networkName: String) {
        guard qrScanViewCoordinator == nil else {
            AppLogger.error(error: "Attempt to present multiple QR scan view coordinators")
            return
        }

        let qrScanViewCoordinator = QRScanViewCoordinator { [weak self] in
            self?.qrScanViewCoordinator = nil
        }

        let text = Localization.sendQrcodeScanInfo(networkName)
        let options = QRScanViewCoordinator.Options(code: codeBinding, text: text)
        qrScanViewCoordinator.start(with: options)

        self.qrScanViewCoordinator = qrScanViewCoordinator
    }
}

// MARK: - SendRoutable

extension SendCoordinator: SendRoutable {
    func dismiss(reason: SendDismissReason) {
        let dismissOptions = mapDismissReasonToDismissOptions(reason)
        dismiss(with: dismissOptions)
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToSendTx)
    }

    func openExplorer(url: URL) {
        safariManager.openURL(url)
    }

    func openShareSheet(url: URL) {
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    func openFeeCurrency(for walletModel: any WalletModel, userWalletModel: UserWalletModel) {
        dismiss(with: .openFeeCurrency(walletModel: walletModel, userWalletModel: userWalletModel))
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

    func openFeeSelector(viewModel: FeeSelectorContentViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openSwapProvidersSelector(viewModel: SendSwapProvidersSelectorViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openReceiveTokensList(tokensListBuilder: SendReceiveTokensListBuilder) {
        let coordinator = SendReceiveTokenCoordinator(
            receiveTokensListBuilder: tokensListBuilder,
            dismissAction: { [weak self] in
                self?.sendReceiveTokenCoordinator = nil
            }, popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)
        sendReceiveTokenCoordinator = coordinator
    }

    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
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
