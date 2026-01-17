//
//  SendRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemExpress
import TangemFoundation
import struct TangemUIUtils.AlertBinder

protocol SendRoutable: SendDestinationRoutable, OnrampRoutable, SendFeeSelectorRoutable, AnyObject {
    func dismiss(reason: SendDismissReason)
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openQRScanner(with codeBinding: Binding<String>, networkName: String)
    func openFeeCurrency(feeCurrency: FeeCurrencyNavigatingDismissOption)
    func openExplorer(url: URL)
    func openShareSheet(url: URL)
    func openApproveView(expressApproveViewModelInput: ExpressApproveViewModel.Input)
    func openFeeSelector(feeSelectorBuilder: SendFeeSelectorBuilder)
    func openSwapProvidersSelector(viewModel: SendSwapProvidersSelectorViewModel)
    func openReceiveTokensList(tokensListBuilder: SendReceiveTokensListBuilder)
    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel)
    func openAccountInitializationFlow(viewModel: BlockchainAccountInitializationViewModel)
    func openFeeSelectorLearnMoreURL(_ url: URL)
}
