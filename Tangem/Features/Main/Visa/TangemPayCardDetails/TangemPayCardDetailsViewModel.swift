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
import TangemVisa

final class TangemPayCardDetailsViewModel: ObservableObject {
    @Published private(set) var state: TangemPayCardDetailsState = .hidden
    @Published private(set) var cardDetailsData: TangemPayCardDetailsData

    private let customerInfoManagementService: any CustomerInfoManagementService

    private var bag = Set<AnyCancellable>()
    private var cardDetailsExposureTask: Task<Void, Never>?

    init(lastFourDigits: String, customerInfoManagementService: any CustomerInfoManagementService) {
        cardDetailsData = .hidden(lastFourDigits: lastFourDigits)
        self.customerInfoManagementService = customerInfoManagementService

        $state
            .map { state -> TangemPayCardDetailsData in
                switch state {
                case .loaded(let cardDetails):
                    cardDetails
                case .hidden, .loading:
                    .hidden(lastFourDigits: lastFourDigits)
                }
            }
            .assign(to: \.cardDetailsData, on: self, ownership: .weak)
            .store(in: &bag)

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

    private func revealRequest() async throws -> TangemPayCardDetailsData {
        let publicKey = try await RainCryptoUtilities.getRainRSAPublicKey(for: FeatureStorage.instance.visaAPIType)
        let (secretKey, sessionId) = try RainCryptoUtilities.generateSecretKeyAndSessionId(publicKey: publicKey)

        let cardDetails = try await customerInfoManagementService.getCardDetails(sessionId: sessionId)

        let decryptedPan = try RainCryptoUtilities.decryptSecret(
            base64Secret: cardDetails.pan.secret,
            base64Iv: cardDetails.pan.iv,
            secretKey: secretKey
        )

        let decryptedCVV = try RainCryptoUtilities.decryptSecret(
            base64Secret: cardDetails.cvv.secret,
            base64Iv: cardDetails.cvv.iv,
            secretKey: secretKey
        )

        let formattedPan = formatPan(decryptedPan)
        let formattedExpiryDate = formatExpiryDate(month: cardDetails.expirationMonth, year: cardDetails.expirationYear)

        return TangemPayCardDetailsData(
            number: formattedPan,
            expirationDate: formattedExpiryDate,
            cvc: decryptedCVV
        )
    }
}

private extension TangemPayCardDetailsViewModel {
    enum Constants {
        static let cardDetailsVisibilityPeriodInSeconds: TimeInterval = 30
    }

    func formatPan(_ pan: String) -> String {
        let cleanPan = pan.replacingOccurrences(of: " ", with: "")
        var formattedPan = ""

        for (index, character) in cleanPan.enumerated() {
            if index > 0, index % 4 == 0 {
                formattedPan += " "
            }
            formattedPan += String(character)
        }

        return formattedPan
    }

    func formatExpiryDate(month: String, year: String) -> String {
        let monthInt = Int(month) ?? 0
        let formattedMonth = String(format: "%02d", monthInt)
        let formattedYear = String(year).suffix(2)
        return "\(formattedMonth)/\(formattedYear)"
    }
}
