//
//  WalletConnectPayViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemFoundation
import protocol TangemUI.FloatingSheetContentViewModel

@MainActor
final class WalletConnectPayViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    @Published private(set) var step: Step = .loading
    @Published private(set) var targets: [WalletConnectPayTarget] = []
    @Published var selectedTargetId: String?
    @Published var selectedOptionId: String?

    @Published private(set) var optionsResponse: WalletConnectPayOptionsResponse?
    @Published private(set) var actions: [WalletConnectPayAction] = []

    private let link: WalletConnectPayLink
    private let userWalletRepository: any UserWalletRepository
    private let makeInteractor: (any UserWalletModel, any CryptoAccountModel) -> WalletConnectPayInteractor

    init(
        link: WalletConnectPayLink,
        userWalletRepository: some UserWalletRepository,
        makeInteractor: @escaping (any UserWalletModel, any CryptoAccountModel) -> WalletConnectPayInteractor
    ) {
        self.link = link
        self.userWalletRepository = userWalletRepository
        self.makeInteractor = makeInteractor
        targets = Self.makeTargets(from: userWalletRepository.models)
        selectedTargetId = Self.makeDefaultTargetId(
            targets: targets,
            selectedUserWalletId: userWalletRepository.selectedModel?.userWalletId
        )
    }

    var title: String {
        "WalletConnect Pay"
    }

    var merchantName: String {
        optionsResponse?.info?.merchant.name ?? "Merchant"
    }

    var merchantIconURL: URL? {
        optionsResponse?.info?.merchant.iconUrl.flatMap(URL.init(string:))
    }

    var options: [WalletConnectPayOption] {
        optionsResponse?.options ?? []
    }

    var selectedOption: WalletConnectPayOption? {
        guard let selectedOptionId else { return options.first }
        return options.first { $0.id == selectedOptionId } ?? options.first
    }

    var primaryButtonTitle: String {
        switch step {
        case .options:
            return "Continue"
        case .result, .error:
            return "Close"
        case .loading, .dataCollection, .signing:
            return "Please wait"
        }
    }

    func loadPaymentOptions() {
        guard let selected = selectedTarget() else {
            step = .error("No WalletConnect-compatible account found")
            return
        }

        step = .loading

        Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await selected.interactor.loadOptions(
                    link: link,
                    userWalletModel: selected.userWalletModel,
                    account: selected.account
                )

                optionsResponse = response
                selectedOptionId = response.options.first?.id
                step = response.options.isEmpty ? .result(.noOptions) : .options
            } catch {
                step = .error(Self.errorMessage(from: error))
            }
        }
    }

    func selectTarget(_ targetId: String) {
        guard selectedTargetId != targetId else { return }
        selectedTargetId = targetId
        loadPaymentOptions()
    }

    func selectOption(_ optionId: String) {
        selectedOptionId = optionId
    }

    func handlePrimaryButtonTap() {
        switch step {
        case .options:
            continueFromOptions()
        case .result, .error:
            close()
        case .loading, .dataCollection, .signing:
            break
        }
    }

    func handleDataCollectionComplete() {
        confirmPayment()
    }

    func handleDataCollectionError(_ message: String) {
        step = .error(message)
    }

    func close() {
        floatingSheetPresenter.removeActiveSheet()
    }

    private func continueFromOptions() {
        guard let option = selectedOption else {
            step = .error("Please select a payment option")
            return
        }

        let collectData = option.collectData ?? optionsResponse?.collectData
        if let urlString = collectData?.url,
           let url = URL(string: urlString),
           Self.isTrustedDataCollectionURL(url) {
            step = .dataCollection(url)
            return
        }

        confirmPayment()
    }

    private func confirmPayment() {
        guard
            let selected = selectedTarget(),
            let option = selectedOption,
            let paymentId = optionsResponse?.paymentId
        else {
            step = .error("Payment option is missing")
            return
        }

        step = .signing

        Task { [weak self] in
            guard let self else { return }

            do {
                let actions = try await selected.interactor.loadActions(paymentId: paymentId, optionId: option.id)
                self.actions = actions

                let signatures = try await selected.interactor.signActions(actions)
                let result = try await selected.interactor.confirmPayment(
                    paymentId: paymentId,
                    optionId: option.id,
                    signatures: signatures
                )

                step = .result(.from(result))
            } catch {
                step = .error(Self.errorMessage(from: error))
            }
        }
    }

    private func selectedTarget() -> (
        userWalletModel: any UserWalletModel,
        account: any CryptoAccountModel,
        interactor: WalletConnectPayInteractor
    )? {
        guard let selectedTargetId else { return nil }

        for userWalletModel in userWalletRepository.models {
            guard userWalletModel.config.isFeatureVisible(.walletConnect) else {
                continue
            }

            for account in Self.cryptoAccounts(from: userWalletModel.accountModelsManager.accountModels) {
                guard Self.makeTargetId(userWalletId: userWalletModel.userWalletId, accountId: account.id.walletConnectIdentifierString) == selectedTargetId else {
                    continue
                }

                return (
                    userWalletModel,
                    account,
                    makeInteractor(userWalletModel, account)
                )
            }
        }

        return nil
    }

    private static func makeTargets(from userWalletModels: [any UserWalletModel]) -> [WalletConnectPayTarget] {
        userWalletModels
            .filter { $0.config.isFeatureVisible(.walletConnect) }
            .flatMap { userWalletModel in
                cryptoAccounts(from: userWalletModel.accountModelsManager.accountModels).map { account in
                    let accountId = account.id.walletConnectIdentifierString
                    return WalletConnectPayTarget(
                        id: makeTargetId(userWalletId: userWalletModel.userWalletId, accountId: accountId),
                        userWalletId: userWalletModel.userWalletId,
                        accountId: accountId,
                        title: account.name,
                        userWalletName: userWalletModel.name
                    )
                }
            }
    }

    private static func makeDefaultTargetId(
        targets: [WalletConnectPayTarget],
        selectedUserWalletId: UserWalletId?
    ) -> String? {
        if let selectedUserWalletId,
           let target = targets.first(where: { $0.userWalletId == selectedUserWalletId }) {
            return target.id
        }

        return targets.first?.id
    }

    private static func cryptoAccounts(from accountModels: [AccountModel]) -> [any CryptoAccountModel] {
        accountModels.flatMap { accountModel -> [any CryptoAccountModel] in
            switch accountModel {
            case .standard(.single(let account)):
                return [account]
            case .standard(.multiple(let accounts)):
                return accounts
            case .tangemPay:
                return []
            }
        }
    }

    private static func makeTargetId(userWalletId: UserWalletId, accountId: String) -> String {
        "\(userWalletId.stringValue):\(accountId)"
    }

    private static func isTrustedDataCollectionURL(_ url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }

        return [
            "dev.pay.walletconnect.com",
            "staging.pay.walletconnect.com",
            "pay.walletconnect.com",
        ].contains(host)
    }

    private static func errorMessage(from error: some Error) -> String {
        error.toUniversalError().errorDescription ?? "Payment failed. Please try again."
    }
}

private extension WalletConnectPayResultState {
    static var noOptions: WalletConnectPayResultState {
        WalletConnectPayResultState(
            kind: .failed,
            title: "No payment options",
            message: "There are no available payment options for the selected wallet."
        )
    }

    static func from(_ result: WalletConnectPayResult) -> WalletConnectPayResultState {
        switch result.status {
        case .succeeded:
            return WalletConnectPayResultState(kind: .success, title: "Payment sent", message: "Your payment has been completed.")
        case .processing, .requiresAction:
            return WalletConnectPayResultState(kind: .processing, title: "Payment processing", message: "Your payment is being processed.")
        case .failed:
            return WalletConnectPayResultState(kind: .failed, title: "Payment failed", message: "The payment could not be completed.")
        case .expired:
            return WalletConnectPayResultState(kind: .expired, title: "Payment expired", message: "The payment link has expired.")
        case .cancelled:
            return WalletConnectPayResultState(kind: .cancelled, title: "Payment cancelled", message: "The payment was cancelled.")
        }
    }
}
