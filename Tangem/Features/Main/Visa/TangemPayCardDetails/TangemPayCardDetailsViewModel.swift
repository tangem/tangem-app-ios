//
//  TangemPayCardDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import Foundation
import UIKit
import TangemUI
import TangemFoundation
import TangemVisa

final class TangemPayCardDetailsViewModel: ObservableObject {
    let lastFourDigits: String

    @Published var state: TangemPayCardDetailsState = .hidden(isFrozen: false)
    @Published var isFlipped: Bool = false

    private var expectedState: TangemPayCardDetailsState? = nil

    private var bag = Set<AnyCancellable>()
    private var cardDetailsExposureTask: Task<Void, Never>?
    private let repository: TangemPayCardDetailsRepository

    init(
        repository: TangemPayCardDetailsRepository
    ) {
        self.repository = repository
        lastFourDigits = repository.lastFourDigits

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.cardDetailsExposureTask?.cancel()
            }
            .store(in: &bag)
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
        guard !state.isLoaded else {
            cardDetailsExposureTask?.cancel()
            return
        }

        toggleInteractive()
    }

    func changeStateIfNeeded() {
        guard let expectedState else { return }
        state = expectedState
        self.expectedState = nil
    }

    private func flip(to state: TangemPayCardDetailsState) {
        expectedState = state
        isFlipped = state.isFlipped
    }

    private func copyAction(copiedTextKeyPath: KeyPath<TangemPayCardDetailsData, String>, toastMessage: String) {
        guard let cardDetailsData = state.details else { return }
        UIPasteboard.general.string = cardDetailsData[keyPath: copiedTextKeyPath]
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")

        Toast(view: SuccessToast(text: toastMessage))
            .present(
                layout: .top(padding: 12),
                type: .temporary()
            )
    }

    private func toggleInteractive() {
        state = .loading(isFrozen: state.isFrozen)
        cardDetailsExposureTask = runTask(in: self) { @MainActor viewModel in
            do {
                let cardDetailsData = try await viewModel.repository.revealRequest()
                viewModel.flip(to: .loaded(.revealed(cardDetailsData)))

                try? await Task.sleep(for: .seconds(Constants.cardDetailsVisibilityPeriodInSeconds))
                viewModel.flip(to: .hidden(isFrozen: viewModel.state.isFrozen))
            } catch {
                viewModel.state = .hidden(isFrozen: viewModel.state.isFrozen)
                AppLogger.error("Failed to load card details", error: error)
            }
        }
    }
}

private extension TangemPayCardDetailsViewModel {
    enum Constants {
        static let cardDetailsVisibilityPeriodInSeconds: TimeInterval = 30
    }
}
