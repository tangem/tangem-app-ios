//
//  TangemPayCardRenameViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemUIUtils

final class TangemPayCardRenameViewModel: ObservableObject, Identifiable {
    let renameCardDetailsViewModel: TangemPayCardDetailsViewModel

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSaveDisabled: Bool = true
    @Published var alert: AlertBinder?

    private let repository: TangemPayCardDetailsRepository
    private let onDismiss: () -> Void

    private var bag = Set<AnyCancellable>()

    init(
        userWalletId: UserWalletId,
        repository: TangemPayCardDetailsRepository,
        onDismiss: @escaping () -> Void
    ) {
        self.repository = repository
        self.onDismiss = onDismiss

        renameCardDetailsViewModel = TangemPayCardDetailsViewModel(
            userWalletId: userWalletId,
            repository: repository,
            cardNameDisplayMode: .editing
        )

        bind()
    }

    func save() {
        let trimmedName = renameCardDetailsViewModel.cardName
            .trimmingCharacters(in: .whitespaces)

        guard isLengthValid(trimmedName) else { return }

        if hasInvalidCharacters(trimmedName) {
            showInvalidCharactersAlert()
            return
        }

        isLoading = true

        runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.repository.updateCardDisplayName(trimmedName)
                viewModel.isLoading = false
                viewModel.onDismiss()
            } catch {
                viewModel.isLoading = false
                viewModel.alert = AlertBinder(
                    title: Localization.tangemPayCardDetailsUnableToRenameCardTitle,
                    message: Localization.tangempayCardDetailsUnableToRenameCardDescription
                )
            }
        }
    }

    func close() {
        onDismiss()
    }
}

private extension TangemPayCardRenameViewModel {
    func bind() {
        renameCardDetailsViewModel.$cardName
            .withWeakCaptureOf(self)
            .map { viewModel, name in
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                return !viewModel.isLengthValid(trimmed)
            }
            .receiveOnMain()
            .assign(to: &$isSaveDisabled)

        $isLoading
            .receiveOnMain()
            .assign(to: \.isCardNameEditingDisabled, on: renameCardDetailsViewModel, ownership: .weak)
            .store(in: &bag)
    }

    func isLengthValid(_ name: String) -> Bool {
        !name.isEmpty && name.count <= Constants.maxCardNameLength
    }

    func hasInvalidCharacters(_ name: String) -> Bool {
        !name.unicodeScalars.allSatisfy { Constants.allowedCardNameCharacters.contains($0) }
    }

    func showInvalidCharactersAlert() {
        alert = AlertBinder(
            title: Localization.tangempayCardDetailsRenameCardInvalidTitle,
            message: Localization.tangempayCardDetailsRenameCardInvalidDescription
        )
    }

    enum Constants {
        static let maxCardNameLength = 20
        static let allowedCardNameCharacters: CharacterSet = .letters.union(.decimalDigits).union(.init(charactersIn: " "))
    }
}
