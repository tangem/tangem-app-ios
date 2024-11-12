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

class SendRoutableMock: SendRoutable {
    func dismiss() {}
    func openFeeExplanation(url: URL) {}
    func openMail(with dataCollector: EmailDataCollector, recipient: String) {}
    func openExplorer(url: URL) {}
    func openShareSheet(url: URL) {}
    func openQRScanner(with codeBinding: Binding<String>, networkName: String) {}
    func openFeeCurrency(for walletModel: WalletModel, userWalletModel: UserWalletModel) {}
    func openApproveView(settings: ExpressApproveViewModel.Settings, approveViewModelInput: any ApproveViewModelInput) {}
    func openOnrampCountryDetection(country: OnrampCountry, repository: any OnrampRepository) {}
    func openOnrampCountrySelector(repository: any OnrampRepository, dataRepository: any OnrampDataRepository) {}
    func openOnrampSettings(repository: any OnrampRepository) {}
    func openOnrampCurrencySelector(repository: any OnrampRepository, dataRepository: any OnrampDataRepository) {}
    func openOnrampCurrencySelector() {}

    func openOnrampProviders() {}
}
