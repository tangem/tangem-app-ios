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
import TangemFoundation

final class SendCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.alertPresenter) private var alertPresenter: any AlertPresenter

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SendViewModel?

    // MARK: - Child coordinators

    @Published var qrScanViewCoordinator: QRScanViewCoordinator? {
        willSet { newValue != nil ? stateProvider.childPresented() : stateProvider.childDismissed() }
    }

    @Published var onrampCountryDetectionCoordinator: OnrampCountryDetectionCoordinator? {
        willSet { newValue != nil ? stateProvider.childPresented() : stateProvider.childDismissed() }
    }

    @Published var sendReceiveTokenCoordinator: SendReceiveTokenCoordinator? {
        willSet { newValue != nil ? stateProvider.childPresented() : stateProvider.childDismissed() }
    }

    // MARK: - Child view models

    @Published var expressApproveViewModel: ApproveViewModel? {
        willSet { newValue != nil ? stateProvider.childPresented() : stateProvider.childDismissed() }
    }

    @Published var swapTokenSelectorViewModel: SwapTokenSelectorViewModel? {
        willSet { newValue != nil ? stateProvider.childPresented() : stateProvider.childDismissed() }
    }

    @Published var onrampSettingsViewModel: OnrampSettingsViewModel?
    @Published var onrampCountrySelectorViewModel: OnrampCountrySelectorViewModel?
    @Published var onrampCurrencySelectorViewModel: OnrampCurrencySelectorViewModel?
    @Published var onrampRedirectingViewModel: OnrampRedirectingViewModel?

    let supportChatPresenter = SupportChatPresenter()

    private var marketsTokenAdditionCoordinator: SwapMarketsTokenAdditionCoordinator?
    private var safariHandle: SafariHandle?

    private let stateProvider = CommonSendCoordinatorStateProvider()

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        guard isWalletBackupStatusValid(options) else {
            assertionFailure("UserWalletBackupState is invalid. Do not allow to continue.")
            return dismiss(reason: .other)
        }

        let flowFactory = SendFactory().flowFactory(options: options)
        rootViewModel = flowFactory
            .make(router: self, coordinatorStateProvider: stateProvider)
    }

    private func isWalletBackupStatusValid(_ options: Options) -> Bool {
        switch options.type {
        case .onramp(let sourceToken, _):
            // Onramp credits the wallet, so block it on a card-linked (non-toppable) wallet.
            if let alert = UserWalletBackupStatusHelper().alert(for: sourceToken.userWalletInfo) {
                alertPresenter.present(alert: alert)
                return false
            }

            return true
        default:
            return true
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
        let type: SendType
        let source: Source
        let shouldStartFromTokenList: Bool

        init(
            type: SendType,
            source: Source,
            shouldStartFromTokenList: Bool = false
        ) {
            self.type = type
            self.source = source
            self.shouldStartFromTokenList = shouldStartFromTokenList
        }
    }

    enum Source {
        case main
        case tokenDetails
        case stakingDetails
        case markets
        case actionButtons
        case nft
        case onboarding
        case qrScan

        var analytics: Analytics.ParameterValue {
            switch self {
            case .main: .longTap
            case .tokenDetails: .token
            case .stakingDetails: .token
            case .markets: .markets
            case .actionButtons: .main
            case .nft: .nft
            case .onboarding: .onboarding
            case .qrScan: .qr
            }
        }
    }

    enum DismissOptions {
        case openFeeCurrency(feeCurrency: FeeCurrencyNavigatingDismissOption)
        case openSwap(SwapNavigatingDismissOption)
        case closeButtonTap
    }
}

// MARK: - SupportChatPresenting

extension SendCoordinator: SupportChatPresenting {}

// MARK: - SendRoutable

extension SendCoordinator: SendRoutable {
    func dismiss(reason: SendDismissReason) {
        let dismissOptions = mapDismissReasonToDismissOptions(reason)
        dismiss(with: dismissOptions)
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToSendTx)

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    func openSwapSupportSelection(with dataCollector: EmailDataCollector, recipient: String, chatDataCollector: ChatDataCollector) {
        let chatInput = SupportChatInputModel(
            logsComposer: LogsComposer(infoProvider: dataCollector),
            userIdentifier: chatDataCollector.userIdentifier,
            source: .swap,
            initialMessage: .swap(message: chatDataCollector.message)
        )

        openSupportTypeSelection(
            emailAction: { [weak self] in self?.openMail(with: dataCollector, recipient: recipient) },
            chatInput: chatInput
        )
    }

    func openExplorer(url: URL) {
        safariManager.openURL(url)
    }

    func openShareSheet(url: URL) {
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    func openFeeCurrency(feeCurrency: FeeCurrencyNavigatingDismissOption) {
        dismiss(with: .openFeeCurrency(feeCurrency: feeCurrency))
    }

    func openApproveView(flowFactory: ApproveFlowFactory) {
        let viewModel = flowFactory.make(router: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openFeeSelector(feeSelectorBuilder: SendFeeSelectorBuilder) {
        guard let viewModel = feeSelectorBuilder.makeSendFeeSelector(router: self) else {
            return
        }

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openSwapProvidersSelector(viewModel: SendSwapProvidersSelectorViewModel) {
        Task { @MainActor in
            UIApplication.shared.endEditing()
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openReceiveTokensList(tokensListBuilder: SendReceiveTokensListBuilder, onDismiss: (() -> Void)?) {
        let coordinator = SendReceiveTokenCoordinator(
            receiveTokensListBuilder: tokensListBuilder,
            dismissAction: { [weak self] swapOption in
                self?.sendReceiveTokenCoordinator = nil
                onDismiss?()

                if let swapOption {
                    self?.dismiss(with: .openSwap(swapOption))
                }
            }, popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)
        sendReceiveTokenCoordinator = coordinator
    }

    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel) {
        Task { @MainActor in
            UIApplication.shared.endEditing()
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openRateInfoSheet(rateType: RateInfoSheetViewModel.RateType, onDismiss: @escaping () -> Void) {
        let viewModel = RateInfoSheetViewModel(rateType: rateType, onDismiss: { [floatingSheetPresenter] in
            Task { @MainActor in
                floatingSheetPresenter.removeActiveSheet()
            }
            onDismiss()
        })
        Task { @MainActor in
            UIApplication.shared.endEditing()
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openAccountInitializationFlow(viewModel: BlockchainAccountInitializationViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openFeeSelectorLearnMoreURL(_ url: URL) {
        Task { @MainActor in
            floatingSheetPresenter.pauseSheetsDisplaying()
            safariHandle = safariManager.openURL(
                url,
                configuration: .init(),
                onDismiss: { [weak self] in self?.floatingSheetPresenter.resumeSheetsDisplaying() },
                onSuccess: { [weak self] _ in self?.floatingSheetPresenter.resumeSheetsDisplaying() },
            )
        }
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

// MARK: - SwapRoutable

extension SendCoordinator: SwapRoutable {
    func openBackupErrorSupport(userWalletInfo: UserWalletInfo) {
        UserWalletBackupStatusHelper().openBackupErrorSupport(for: userWalletInfo)
    }

    func openSwapTokenSelector(
        swapTokenSelectorViewModelBuilder: SwapTokenSelectorViewModelBuilder,
        direction: SwapTokenSelectorViewModel.SwapDirection
    ) {
        let marketsTokenAdditionCoordinator = SwapMarketsTokenAdditionCoordinator(onTokenAdded: { [weak self] item in
            guard let viewModel = self?.swapTokenSelectorViewModel else {
                AppLogger.error(error: "SwapTokenSelectorViewModel not found")
                return
            }
            viewModel.selectNewToken(item)
        })

        self.marketsTokenAdditionCoordinator = marketsTokenAdditionCoordinator

        let marketsTokensViewModel = SwapMarketsTokensViewModel()

        swapTokenSelectorViewModel = swapTokenSelectorViewModelBuilder.makeSwapTokenSelectorViewModel(
            direction: direction,
            router: self,
            marketsTokensViewModel: marketsTokensViewModel,
            marketsTokenAdditionRouter: marketsTokenAdditionCoordinator
        )
    }
}

// MARK: - SwapTokenSelectorRoutable

extension SendCoordinator: SwapTokenSelectorRoutable {
    func closeSwapTokenSelector() {
        swapTokenSelectorViewModel = nil
    }
}

// MARK: - OnrampRoutable

extension SendCoordinator: OnrampRoutable {
    func openOnrampCountryDetection(
        country: OnrampCountry,
        repository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        onCountrySelected: @escaping () -> Void
    ) {
        let coordinator = OnrampCountryDetectionCoordinator(dismissAction: { [weak self] option in
            switch option {
            case .none:
                self?.onrampCountryDetectionCoordinator = nil
                onCountrySelected()
            case .closeOnramp:
                self?.dismiss(with: nil)
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

    func openOnrampSettings(repository: any OnrampRepository, settingsRoutable: OnrampSettingsRoutable) {
        onrampSettingsViewModel = OnrampSettingsViewModel(
            repository: repository,
            coordinator: settingsRoutable
        )
    }

    func openOnrampCurrencySelector(repository: any OnrampRepository, dataRepository: any OnrampDataRepository) {
        onrampCurrencySelectorViewModel = OnrampCurrencySelectorViewModel(
            repository: repository,
            dataRepository: dataRepository,
            coordinator: self
        )
    }

    func openOnrampOffersSelector(viewModel: OnrampOffersSelectorViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openOnrampRedirecting(onrampRedirectingBuilder: OnrampRedirectingBuilder) {
        onrampRedirectingViewModel = onrampRedirectingBuilder.makeOnrampRedirectingViewModel(coordinator: self)
    }

    func openOnrampWebView(url: URL, onDismiss: @escaping () -> Void, onSuccess: @escaping (URL) -> Void) {
        safariHandle = safariManager.openURL(url, configuration: .init(), onDismiss: { [weak self] in
            self?.cleanupOnrampWebView()
            onDismiss()
        }, onSuccess: { [weak self] url in
            self?.cleanupOnrampWebView()
            onSuccess(url)
        })
    }

    private func cleanupOnrampWebView() {
        safariHandle = nil
        dismissOnrampRedirecting()
    }

    func openOnrampKYCVerification(providerName: String, routable: OnrampKYCVerificationSheetRoutable) {
        Task { @MainActor in
            UIApplication.shared.endEditing()
            floatingSheetPresenter.enqueue(
                sheet: OnrampKYCVerificationSheetViewModel(
                    providerName: providerName,
                    routable: routable
                )
            )
        }
    }
}

// MARK: - ApproveRoutable

extension SendCoordinator: ApproveRoutable {
    func didSendApproveTransaction() {
        Task { @MainActor in floatingSheetPresenter.removeActiveSheet() }
    }

    func userDidCancel() {
        Task { @MainActor in floatingSheetPresenter.removeActiveSheet() }
    }

    func openLearnMoreAboutApprove() {
        openLearnMore()
    }

    func openLearnMore() {
        Task { @MainActor in
            floatingSheetPresenter.pauseSheetsDisplaying()
            safariHandle = safariManager.openURL(
                TangemBlogUrlBuilder().url(post: .giveRevokePermission),
                configuration: .init(),
                onDismiss: { [weak self] in self?.floatingSheetPresenter.resumeSheetsDisplaying() },
                onSuccess: { [weak self] _ in self?.floatingSheetPresenter.resumeSheetsDisplaying() },
            )
        }
    }
}

// MARK: - FeeSelectorRoutable

extension SendCoordinator: FeeSelectorRoutable {
    func closeFeeSelector() {
        Task { @MainActor in floatingSheetPresenter.removeActiveSheet() }
    }
}

// MARK: - OnrampCountrySelectorRoutable

extension SendCoordinator: OnrampCountrySelectorRoutable {
    func dismissCountrySelector() {
        onrampCountrySelectorViewModel = nil
    }
}

// MARK: - OnrampCurrencySelectorRoutable

extension SendCoordinator: OnrampCurrencySelectorRoutable {
    func dismissCurrencySelector() {
        onrampCurrencySelectorViewModel = nil
    }
}

// MARK: - OnrampRedirectingRoutable

extension SendCoordinator: OnrampRedirectingRoutable {
    func dismissOnrampRedirecting() {
        onrampRedirectingViewModel = nil
    }
}
