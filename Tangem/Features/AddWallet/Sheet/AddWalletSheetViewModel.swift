//
//  AddWalletSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

@MainActor
final class AddWalletSheetViewModel: ObservableObject, Identifiable {
    @Published private(set) var state: State = .options
    @Published private(set) var loadingOption: AddWalletSheetOption?

    let title = Localization.userWalletAddWallet
    let options: [AddWalletSheetOption]

    var isLoading: Bool {
        loadingOption != nil
    }

    private weak var delegate: AddWalletSheetDelegate?

    init(options: [AddWalletSheetOption], delegate: AddWalletSheetDelegate) {
        self.options = options
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension AddWalletSheetViewModel {
    func onOptionTap(_ option: AddWalletSheetOption) {
        delegate?.didSelect(option: option)
    }

    func onCloseTap() {
        delegate?.didClose()
    }

    func setLoading(_ option: AddWalletSheetOption?) {
        loadingOption = option
    }

    func showImportWallet(_ viewModel: MobileImportWalletViewModel) {
        state = .importWallet(viewModel)
    }

    func showOptions() {
        state = .options
    }
}

// MARK: - State

extension AddWalletSheetViewModel {
    enum State {
        case options
        case importWallet(MobileImportWalletViewModel)
    }
}
