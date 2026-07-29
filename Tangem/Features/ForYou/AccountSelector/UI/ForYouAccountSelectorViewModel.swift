//
//  ForYouAccountSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

@MainActor
final class ForYouAccountSelectorViewModel: ObservableObject {
    // MARK: - Properties

    private let includesAllWallets: Bool
    private let applySelectionAction: (ForYouAccountSelection) -> Void
    private let dismissAction: () -> Void

    var canApply: Bool {
        !selectedAccountIDs.isEmpty
    }

    // MARK: - Publishers

    @Published private(set) var sections: [ForYouAccountSelectorSection] = []
    @Published private(set) var selectedAccountIDs: Set<ForYouAccountID> = []

    // MARK: - Init

    init(
        userWalletModels: [any UserWalletModel],
        selection: ForYouAccountSelection,
        includesAllWallets: Bool,
        applySelectionAction: @escaping (ForYouAccountSelection) -> Void,
        dismissAction: @escaping () -> Void
    ) {
        self.includesAllWallets = includesAllWallets
        self.applySelectionAction = applySelectionAction
        self.dismissAction = dismissAction

        sections = userWalletModels.selectorSections { [weak self] in
            self?.toggleAccount($0)
        }
        selectedAccountIDs = selection.seededAccountIDs(allIDs: allAccountIDs)
    }

    // MARK: - Internal methods

    func isAccountSelected(_ id: ForYouAccountID) -> Bool {
        selectedAccountIDs.contains(id)
    }

    func isWalletFullySelected(_ section: ForYouAccountSelectorSection) -> Bool {
        let ids = section.accounts.map(\.id)
        return !ids.isEmpty && ids.allSatisfy(selectedAccountIDs.contains)
    }

    func toggleWallet(_ section: ForYouAccountSelectorSection) {
        let ids = section.accounts.map(\.id)

        if isWalletFullySelected(section) {
            selectedAccountIDs.subtract(ids)
        } else {
            selectedAccountIDs.formUnion(ids)
        }
    }

    func apply() {
        // Collapse to symbolic `.all` only when no wallet is locked; otherwise a wallet unlocked
        // later would silently join a selection the user never saw or made.
        let coversEntireUniverse = selectedAccountIDs == allAccountIDs && includesAllWallets
        let selectionToApply: ForYouAccountSelection = coversEntireUniverse ? .all : .subset(selectedAccountIDs)
        applySelectionAction(selectionToApply)
        dismissAction()
    }

    func close() {
        dismissAction()
    }
}

// MARK: - Selection

private extension ForYouAccountSelectorViewModel {
    var allAccountIDs: Set<ForYouAccountID> {
        Set(sections.flatMap { $0.accounts.map(\.id) })
    }

    func toggleAccount(_ id: ForYouAccountID) {
        selectedAccountIDs.formSymmetricDifference([id])
    }
}

private extension ForYouAccountSelection {
    /// `.all` (or a fully stale subset) checks every account; a live subset restores its ids.
    func seededAccountIDs(allIDs: Set<ForYouAccountID>) -> Set<ForYouAccountID> {
        switch self {
        case .all:
            return allIDs
        case .subset(let ids):
            let validSelection = ids.intersection(allIDs)
            return validSelection.isEmpty ? allIDs : validSelection
        }
    }
}

// MARK: - Sections building

private extension Array where Element == UserWalletModel {
    func selectorSections(
        onAccountTap: @escaping (ForYouAccountID) -> Void
    ) -> [ForYouAccountSelectorSection] {
        compactMap { wallet in
            let accounts = wallet.accountModelsManager.cryptoAccountModels

            guard !accounts.isEmpty else {
                return nil
            }

            let items = accounts.map { account in
                let id = ForYouAccountID(account)

                return ForYouAccountSelectorSection.Item(
                    id: id,
                    rowViewModel: AccountRowButtonViewModel(
                        accountModel: account,
                        onTap: { onAccountTap(id) }
                    )
                )
            }

            return ForYouAccountSelectorSection(
                walletId: wallet.userWalletId.stringValue,
                walletName: wallet.name,
                walletThumbnailType: wallet.config.walletThumbnailType,
                accounts: items
            )
        }
    }
}

// MARK: - FloatingSheetContentViewModel

extension ForYouAccountSelectorViewModel: FloatingSheetContentViewModel {}
