//
//  SendRoutableMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemExpress
import TangemFoundation
import TangemUIUtils

class SendRoutableMock: SendRoutable {
    func openLearnMoreAboutApprove() {}
    func dismiss(reason: SendDismissReason) {}
    func openFeeExplanation(url: URL) {}
    func openMail(with dataCollector: EmailDataCollector, recipient: String) {}
    func openExplorer(url: URL) {}
    func openShareSheet(url: URL) {}
    func openQRScanner(with codeBinding: Binding<String>, networkName: String) {}
    func openFeeCurrency(feeCurrency: FeeCurrencyNavigatingDismissOption) {}
    func openApproveView(flowFactory: ApproveFlowFactory) {}
    func openOnrampCountryDetection(country: OnrampCountry, repository: any OnrampRepository, dataRepository: any OnrampDataRepository) {}
    func openOnrampCountryDetection(
        country: OnrampCountry,
        repository: any OnrampRepository,
        dataRepository: any OnrampDataRepository,
        onCountrySelected: @escaping () -> Void
    ) {}
    func openOnrampCountrySelector(repository: any OnrampRepository, dataRepository: any OnrampDataRepository) {}
    func openOnrampSettings(repository: any OnrampRepository, settingsRoutable: any OnrampSettingsRoutable) {}
    func openOnrampCurrencySelector(repository: any OnrampRepository, dataRepository: any OnrampDataRepository) {}
    func openOnrampCurrencySelector() {}
    func openOnrampOffersSelector(viewModel: OnrampOffersSelectorViewModel) {}
    func openOnrampRedirecting(onrampRedirectingBuilder: OnrampRedirectingBuilder) {}
    func openOnrampWebView(url: URL, onDismiss: @escaping () -> Void, onSuccess: @escaping (URL) -> Void) {}
    func openOnrampKYCVerification(providerName: String, routable: OnrampKYCVerificationSheetRoutable) {}
    func openFeeSelector(feeSelectorBuilder: SendFeeSelectorBuilder) {}
    func openSwapProvidersSelector(viewModel: SendSwapProvidersSelectorViewModel) {}
    func openReceiveTokensList(tokensListBuilder: SendReceiveTokensListBuilder, onDismiss: (() -> Void)?) {}
    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel) {}
    func openAccountInitializationFlow(viewModel: BlockchainAccountInitializationViewModel) {}
    func openRateInfoSheet(rateType: RateInfoSheetViewModel.RateType, onDismiss: @escaping () -> Void) {}
    func closeFeeSelector() {}
    func openFeeSelectorLearnMoreURL(_ url: URL) {}
    func openSwapTokenSelector(swapTokenSelectorViewModelBuilder: SwapTokenSelectorViewModelBuilder, direction: SwapTokenSelectorViewModel.SwapDirection) {}
}
