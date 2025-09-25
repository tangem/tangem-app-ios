//
//  TangemPayCardDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import UIKit
import TangemUI
import TangemFoundation

final class TangemPayCardDetailsViewModel: ObservableObject {
    @Published private(set) var state: TangemPayCardDetailsState = .hidden
    @Published private(set) var cardDetailsData: TangemPayCardDetailsData

    private var cancellable: Cancellable?
    private var cardDetailsExposureTask: Task<Void, Never>?

    init(lastFourDigits: String) {
        cardDetailsData = .hidden(lastFourDigits: lastFourDigits)

        $state
            .map { state -> TangemPayCardDetailsData in
                switch state {
                case .loaded(let cardDetails):
                    cardDetails
                case .hidden, .loading:
                    .hidden(lastFourDigits: lastFourDigits)
                }
            }
            .assign(to: &$cardDetailsData)

        cancellable = NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.cardDetailsExposureTask?.cancel()
            }
    }

    func copyNumber() {
        copyAction(copiedTextKeyPath: \.number, toastMessage: "Number copied")
    }

    func copyExpirationDate() {
        copyAction(copiedTextKeyPath: \.expirationDate, toastMessage: "Expiration date copied")
    }

    func copyCVC() {
        copyAction(copiedTextKeyPath: \.cvc, toastMessage: "CVC copied")
    }

    func toggleVisibility() {
        guard state.isHidden else {
            cardDetailsExposureTask?.cancel()
            return
        }

        state = .loading
        cardDetailsExposureTask = runTask(in: self) { @MainActor viewModel in
            do {
                let cardDetailsData = try await viewModel.revealRequest()
                viewModel.state = .loaded(cardDetailsData)

                try? await Task.sleep(seconds: Constants.cardDetailsVisibilityPeriodInSeconds)
                viewModel.state = .hidden
            } catch {
                // [REDACTED_TODO_COMMENT]
            }
        }
    }

    private func copyAction(copiedTextKeyPath: KeyPath<TangemPayCardDetailsData, String>, toastMessage: String) {
        guard case .loaded(let cardDetailsData) = state else {
            return
        }

        UIPasteboard.general.string = cardDetailsData[keyPath: copiedTextKeyPath]
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")

        Toast(view: SuccessToast(text: toastMessage))
            .present(
                layout: .top(padding: 12),
                type: .temporary()
            )
    }

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_INFO]
    private func revealRequest() async throws -> TangemPayCardDetailsData {
        try? await Task.sleep(seconds: 2)
        return TangemPayCardDetailsData(
            number: "1234 5678 1234 1245",
            expirationDate: "12/27",
            cvc: "123"
        )
    }
}

private extension TangemPayCardDetailsViewModel {
    enum Constants {
        static let cardDetailsVisibilityPeriodInSeconds: TimeInterval = 30
    }
}
