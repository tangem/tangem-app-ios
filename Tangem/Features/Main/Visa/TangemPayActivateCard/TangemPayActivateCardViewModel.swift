//
//  TangemPayActivateCardViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

final class TangemPayActivateCardViewModel: ObservableObject, Identifiable {
    @Published private(set) var digits = ""
    @Published private(set) var isActivating = false
    @Published private(set) var isEntryFocused = false

    let digitCount = Constants.digitCount

    var activationImageURL: URL? {
        card.activationImageURL
    }

    var hint: String {
        isActivating
            ? Localization.tangempayCardActivationInProgress
            : Localization.tangempayCardActivationDescription
    }

    var isContinueEnabled: Bool {
        digits.count == digitCount
    }

    private let card: TangemPayPlasticCardStub
    private weak var coordinator: TangemPayActivateCardRoutable?
    private var activationTask: Task<Void, Never>?

    init(card: TangemPayPlasticCardStub, coordinator: TangemPayActivateCardRoutable?) {
        self.card = card
        self.coordinator = coordinator
    }

    func focusEntry() {
        isEntryFocused = true
    }

    /// The keypad stays up through the request, so the digits freeze instead of the field being dismissed.
    func updateDigits(_ digits: String) {
        guard !isActivating else { return }

        self.digits = digits
    }

    func activate() {
        guard isContinueEnabled, !isActivating else { return }

        isActivating = true

        activationTask = runTask(in: self) { @MainActor viewModel in
            // [REDACTED_TODO_COMMENT]
            try? await Task.sleep(for: Constants.activationDuration)

            guard !Task.isCancelled else { return }

            viewModel.coordinator?.activateCardDidFinish(cardId: viewModel.card.id)
        }
    }

    func close() {
        activationTask?.cancel()
        isEntryFocused = false
        coordinator?.closeActivateCard()
    }
}

// MARK: - Constants

private extension TangemPayActivateCardViewModel {
    enum Constants {
        static let digitCount = 4
        static let activationDuration: Duration = .seconds(2)
    }
}
