//
//  AddCustomTokenDerivationPathWriterViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization
import TangemSdk
import TangemMacro
import BlockchainSdk

protocol AddCustomTokenDerivationPathWriterOutput: AnyObject {
    func didEnterCustomDerivation(_ derivationPath: String)
}

final class AddCustomTokenDerivationPathWriterViewModel: ObservableObject, Identifiable {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    @Published var derivationPathText: String
    @Published var derivationPathState: State = .empty

    private let context: ManageTokensContext
    private let blockchain: Blockchain
    private weak var output: AddCustomTokenDerivationPathWriterOutput?

    init(
        currentDerivationPath: String,
        context: ManageTokensContext,
        blockchain: Blockchain,
        output: AddCustomTokenDerivationPathWriterOutput
    ) {
        derivationPathText = currentDerivationPath
        self.context = context
        self.blockchain = blockchain
        self.output = output

        bind()
    }

    func save() {
        guard let derivationPath = try? DerivationPath(rawPath: derivationPathText) else {
            return
        }

        let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: derivationPath))
        let destination = context.accountDestination(for: tokenItem)

        switch destination {
        case .currentAccount:
            output?.didEnterCustomDerivation(derivationPathText)

        case .differentAccount(let accountName, _):
            showAccountMismatchAlert(accountName: accountName)
        }
    }

    private func bind() {
        $derivationPathText
            .withWeakCaptureOf(self)
            .map { $0.validate(rawPath: $1) }
            .assign(to: &$derivationPathState)
    }

    private func validate(rawPath: String) -> State {
        guard !rawPath.isEmpty else {
            return .empty
        }

        do {
            let derivationPath = try DerivationPath(rawPath: rawPath)
            let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: derivationPath))

            guard !context.hasDynamicAddressRestriction(for: tokenItem) else {
                return .failure(hint: Localization.dynamicAddressesCustomTokenErrorOnAddition)
            }

            return .success
        } catch {
            return .failure(hint: .none)
        }
    }

    private func showAccountMismatchAlert(accountName: String) {
        let alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: Localization.customTokenAnotherAccountDialogTitle,
            message: Localization.customTokenAnotherAccountDialogDescription(accountName),
            buttonText: Localization.commonGotIt,
            buttonAction: { [weak self, derivationPathText] in
                self?.output?.didEnterCustomDerivation(derivationPathText)
            }
        )
        alertPresenter.present(alert: alert)
    }
}

extension AddCustomTokenDerivationPathWriterViewModel {
    @CaseFlagable
    enum State: Hashable {
        case empty
        case success
        case failure(hint: String?)
    }
}
