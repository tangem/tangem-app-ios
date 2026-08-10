//
//  TangemPayVirtualAccountInfoSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemUIUtils
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemVisa

@MainActor
final class TangemPayVirtualAccountInfoSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var state: State = .loading
    @Published private(set) var isLoading = false
    @Published var alert: AlertBinder?

    var agreementText: AttributedString {
        let terms = Localization.tangempayBankTransferTermsOfUse

        var attributedString = AttributedString(Localization.tangempayBankTransferLegal(terms))

        if let range = attributedString.range(of: terms) {
            attributedString[range].link = AppConstants.tangemPayVirtualAccountTermsURL
        }

        return attributedString
    }

    private let tangemPayAccount: TangemPayAccount
    private let isFirstTimeConditions: Bool
    private weak var coordinator: TangemPayVirtualAccountInfoSheetRoutable?

    init(tangemPayAccount: TangemPayAccount, coordinator: TangemPayVirtualAccountInfoSheetRoutable) {
        self.tangemPayAccount = tangemPayAccount
        self.coordinator = coordinator

        isFirstTimeConditions = !AppSettings.shared.tangemPayVirtualAccountConditionsShown
        AppSettings.shared.tangemPayVirtualAccountConditionsShown = true

        Analytics.log(isFirstTimeConditions ? .visaVATopupConditionsPopupShowedFirstTime : .visaVATopupConditionsPopupShowed)

        loadFees()
    }

    func showDetails() {
        guard !isLoading else { return }
        isLoading = true

        Analytics.log(isFirstTimeConditions ? .visaVATopupShowDetailsFirstTimeClicked : .visaVATopupShowDetailsClicked)

        switch tangemPayAccount.virtualAccountEntry {
        case .active(let productInstanceId):
            loadBankCredentials(productInstanceId: productInstanceId)
        case .none, .preparing:
            createVirtualAccountOrder()
        }
    }

    func reloadFees() {
        guard case .failed = state else { return }

        state = .loading

        loadFees()
    }

    private func loadFees() {
        runTask(in: self) { @MainActor viewModel in
            do {
                let fees = try await viewModel.tangemPayAccount.loadOnrampFees()

                guard let ach = fees.first(where: { $0.type == TangemPayFeeType.achOnramp.rawValue }),
                      let fedwire = fees.first(where: { $0.type == TangemPayFeeType.fedwireOnramp.rawValue })
                else {
                    throw TangemPayAccountError.missingOnrampFees
                }

                viewModel.state = .loaded(
                    achFee: Self.format(fee: ach),
                    fedwireFee: Self.format(fee: fedwire)
                )
            } catch {
                VisaLogger.error("Failed to load virtual account onramp fees", error: error)
                viewModel.state = .failed
            }
        }
    }

    private func loadBankCredentials(productInstanceId: String) {
        runTask(in: self) { @MainActor viewModel in
            defer { viewModel.isLoading = false }

            do {
                let credentials = try await viewModel.tangemPayAccount.loadBankCredentials(productInstanceId: productInstanceId)
                viewModel.coordinator?.virtualAccountDidLoadBankCredentials(credentials)
            } catch {
                VisaLogger.error("Failed to load virtual account bank credentials", error: error)
                viewModel.coordinator?.virtualAccountInfoSheetDidFailToLoadBankCredentials(productInstanceId: productInstanceId)
            }
        }
    }

    private func createVirtualAccountOrder() {
        runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.tangemPayAccount.createVirtualAccount()
                viewModel.isLoading = false
                viewModel.coordinator?.virtualAccountInfoSheetDidCreateOrder()
            } catch {
                viewModel.isLoading = false
                // [REDACTED_TODO_COMMENT]
                viewModel.alert = AlertBinder(
                    title: Localization.commonSomethingWentWrong,
                    message: Localization.commonTryAgainLater
                )
            }
        }
    }

    func close() {
        coordinator?.closeVirtualAccountSheet()
    }

    func openURL(_ url: URL) {
        coordinator?.openVirtualAccountURL(url)
    }

    private static func format(fee: TangemPayFeeResponse) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = fee.currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: fee.amount as NSDecimalNumber) ?? "\(fee.amount) \(fee.currency)"
    }
}

extension TangemPayVirtualAccountInfoSheetViewModel {
    enum State: Hashable {
        case loading
        case loaded(achFee: String, fedwireFee: String)
        case failed
    }
}
