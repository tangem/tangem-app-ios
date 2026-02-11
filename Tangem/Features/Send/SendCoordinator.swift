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

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SendViewModel?

    // MARK: - Child coordinators

    @Published var qrScanViewCoordinator: QRScanViewCoordinator?
    @Published var onrampCountryDetectionCoordinator: OnrampCountryDetectionCoordinator?
    @Published var sendReceiveTokenCoordinator: SendReceiveTokenCoordinator?

    // MARK: - Child view models

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
        let flowFactory = SendFactory().flowFactory(options: options)
        rootViewModel = flowFactory.make(router: self)
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
        let input: SendInput
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
        case onboarding

        var analytics: Analytics.ParameterValue {
            switch self {
            case .main: .longTap
            case .tokenDetails: .token
            case .stakingDetails: .token
            case .markets: .markets
            case .actionButtons: .main
            case .nft: .nft
            case .onboarding: .onboarding
            }
        }
    }

    enum DismissOptions {
        case openFeeCurrency(feeCurrency: FeeCurrencyNavigatingDismissOption)
        case closeButtonTap
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
        let mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToSendTx)

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
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

    func openApproveView(expressApproveViewModelInput: ExpressApproveViewModel.Input) {
        expressApproveViewModel = .init(input: expressApproveViewModelInput, coordinator: self)
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

    func openOnrampOffersSelector(viewModel: OnrampOffersSelectorViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
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

    func openLearnMore() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .giveRevokePermission))
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

// MARK: - OnrampRedirectingRoutable

extension SendCoordinator: OnrampRedirectingRoutable {
    func dismissOnrampRedirecting() {
        onrampRedirectingViewModel = nil
    }
}
