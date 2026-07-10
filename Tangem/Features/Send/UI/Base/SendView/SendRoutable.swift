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

protocol SendRoutable: SendDestinationRoutable, OnrampRoutable, SwapRoutable, SendFeeSelectorRoutable, SendSwapProvidersRoutable, AnyObject {
    func dismiss(reason: SendDismissReason)
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openSwapSupportSelection(with dataCollector: EmailDataCollector, recipient: String, chatDataCollector: ChatDataCollector)
    func openQRScanner(with codeBinding: Binding<String>, networkName: String)
    func openFeeCurrency(feeCurrency: FeeCurrencyNavigatingDismissOption)
    func openExplorer(url: URL)
    func openShareSheet(url: URL)
    func openAddContact(addressBookWallet: AddressBookWallet, prefilledEntries: [AddressBookEntryDraft])
    func openApproveView(flowFactory: ApproveFlowFactory)
    func openFeeSelector(feeSelectorBuilder: SendFeeSelectorBuilder)
    func openSwapProvidersSelector(viewModel: SendSwapProvidersSelectorViewModel)
    func openReceiveTokensList(tokensListBuilder: SendReceiveTokensListBuilder, onDismiss: (() -> Void)?)
    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel)
    func openAccountInitializationFlow(viewModel: BlockchainAccountInitializationViewModel)
    func openRateInfoSheet(rateType: RateInfoSheetViewModel.RateType, onDismiss: @escaping () -> Void)
    func openFeeSelectorLearnMoreURL(_ url: URL)
}
