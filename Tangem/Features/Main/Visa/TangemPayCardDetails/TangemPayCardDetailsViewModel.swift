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

    private var cancellable: Cancellable?
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

    private func revealRequest() async throws -> TangemPayCardDetailsData {
        let devPublicKey = try VisaConfigProvider.shared().getRainRSAPublicKey(apiType: .dev)
        let secretKey = UUID().uuidString.replacingOccurrences(of: "-", with: "")

        guard let sessionId = SessionCrypto.generateSessionId(publicKey: devPublicKey, secretKey: secretKey) else {
            // [REDACTED_TODO_COMMENT]
            fatalError()
        }

        let cardDetails = try await customerInfoManagementService.getCardDetails(sessionId: sessionId)

        let decryptedPan = SessionCrypto.decryptSecret(
            base64Secret: cardDetails.pan.secret,
            base64Iv: cardDetails.pan.iv,
            secretKey: secretKey
        )

        let decryptedCVV = SessionCrypto.decryptSecret(
            base64Secret: cardDetails.cvv.secret,
            base64Iv: cardDetails.cvv.iv,
            secretKey: secretKey
        )

        guard let decryptedPan, let decryptedCVV else {
            // [REDACTED_TODO_COMMENT]
            fatalError()
        }

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

import CryptoKit
import Security

enum SessionCrypto {
    private static let tagLength: Int = 16
    
    private static var keyAttributes: CFDictionary {
        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
        ]
        return keyAttributes as CFDictionary
    }

    static func generateSessionId(publicKey: String, secretKey: String) -> String? {
        guard let secretKeyBase64Data = Data(hexString: secretKey).base64EncodedString().data(using: .utf8),
              let keyData = Data(base64Encoded: publicKey),
              let publicKey = SecKeyCreateWithData(keyData as CFData, keyAttributes, nil),
              let encryptedData = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionOAEPSHA1, secretKeyBase64Data as CFData, nil)
        else {
            return nil
        }

        return (encryptedData as Data).base64EncodedString()
    }

    static func decryptSecret(base64Secret: String, base64Iv: String, secretKey: String) -> String? {
        guard let secretData = Data(base64Encoded: base64Secret),
              let ivData = Data(base64Encoded: base64Iv),
              let nonce = try? AES.GCM.Nonce(data: ivData),
              let sealedBox = try? AES.GCM.SealedBox(nonce: nonce, ciphertext: secretData.dropLast(tagLength), tag: secretData.suffix(tagLength)),
              let decryptedData = try? AES.GCM.open(sealedBox, using: SymmetricKey(data: Data(hexString: secretKey))),
              let decryptedString = String(data: decryptedData, encoding: .utf8)
        else {
            return nil
        }

        return decryptedString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
