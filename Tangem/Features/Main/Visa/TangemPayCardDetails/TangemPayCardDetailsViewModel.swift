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
        let devPublicKey = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCAP192809jZyaw62g/eTzJ3P9H+RmT88sXUYjQ0K8Bx+rJ83f22+9isKx+lo5UuV8tvOlKwvdDS/pVbzpG7D7NO45c0zkLOXwDHZkou8fuj8xhDO5Tq3GzcrabNLRLVz3dkx0znfzGOhnY4lkOMIdKxlQbLuVM/dGDC9UpulF+UwIDAQAB"
        let prodPublicKey = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCeZ9uCoxi2XvOw1VmvVLo88TLkGE+OO1j3fa8HhYlJZZ7CCIAsaCorrU+ZpD5PUTnmME3DJk+JyY1BB3p8XI+C5unoQucrbxFbkM1lgR10ewz/LcuhleG0mrXL/bzUZbeJqI6v3c9bXvLPKlsordPanYBGFZkmBPxc8QEdRgH4awIDAQAB"

        let session = try SessionCrypto.generateSessionId(publicKey: devPublicKey)
        let sessionId = session.sessionId
        let secretKey = session.secretKey

        let cardDetails = try await customerInfoManagementService.getCardDetails(sessionId: sessionId)

        let decryptedPan = try SessionCrypto.decryptSecret(
            base64Secret: cardDetails.pan.secret,
            base64Iv: cardDetails.pan.iv,
            secretKey: secretKey
        )

        let decryptedCVV = try SessionCrypto.decryptSecret(
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

import CryptoKit
import Security

public enum EncryptionUtils {
    enum EncryptionError: Error {
        case invalidData
    }

    public static func encryptAESGCM(plaintext: String, secretKey: String) throws -> (ciphertext: Data, tag: Data, nonce: Data) {
        guard let plaintextData = plaintext.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }

        let secretKeyData = Data(hexString: secretKey)
        let key = SymmetricKey(data: secretKeyData)
        let nonce = AES.GCM.Nonce()

        let sealedBox = try AES.GCM.seal(plaintextData, using: key, nonce: nonce)
        return (sealedBox.ciphertext, sealedBox.tag, Data(nonce))
    }

    public static func encryptAESGCM(plaintext: String, secretKey: String, nonce: Data) throws -> (ciphertext: Data, tag: Data, nonce: Data) {
        guard let plaintextData = plaintext.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }

        let secretKeyData = Data(hexString: secretKey)
        let key = SymmetricKey(data: secretKeyData)
        let gcmNonce = try AES.GCM.Nonce(data: nonce)

        let sealedBox = try AES.GCM.seal(plaintextData, using: key, nonce: gcmNonce)
        return (sealedBox.ciphertext, sealedBox.tag, nonce)
    }

    public static func formatForDecryption(ciphertext: Data, tag: Data, nonce: Data) -> (base64Secret: String, base64Iv: String) {
        var combinedData = Data()
        combinedData.append(ciphertext)
        combinedData.append(tag)

        return (combinedData.base64EncodedString(), nonce.base64EncodedString())
    }
}

public enum SessionCrypto {
    enum SessionError: Error {
        case invalidData
    }

    public static func generateSessionId(publicKey: String, secret: String? = nil) throws -> (secretKey: String, sessionId: String) {
        let secretKey = secret ?? UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let secretKeyData = Data(hexString: secretKey)
        guard let secretKeyBase64Data = secretKeyData.base64EncodedString().data(using: .utf8) else {
            throw SessionError.invalidData
        }

        let publicKey = try parsePublicKey(from: publicKey)
        let encryptedData = try encryptWithPublicKey(data: secretKeyBase64Data, publicKey: publicKey)

        return (secretKey, encryptedData.base64EncodedString())
    }

    public static func decryptSecret(base64Secret: String, base64Iv: String, secretKey: String) throws -> String {
        guard let secretData = Data(base64Encoded: base64Secret),
              let ivData = Data(base64Encoded: base64Iv)
        else {
            throw SessionError.invalidData
        }

        let secretKeyData = Data(hexString: secretKey)
        let tagLength = 16
        let ciphertext = secretData.dropLast(tagLength)
        let authTag = secretData.suffix(tagLength)

        let symmetricKey = SymmetricKey(data: secretKeyData)
        let nonce = try AES.GCM.Nonce(data: ivData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: authTag)
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)

        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw SessionError.invalidData
        }

        return decryptedString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parsePublicKey(from publicKey: String) throws -> SecKey {
        guard let keyData = Data(base64Encoded: publicKey) else {
            throw SessionError.invalidData
        }

        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
        ]

        guard let publicKey = SecKeyCreateWithData(keyData as CFData, keyAttributes as CFDictionary, nil) else {
            throw SessionError.invalidData
        }

        return publicKey
    }

    private static func encryptWithPublicKey(data: Data, publicKey: SecKey) throws -> Data {
        let algorithm = SecKeyAlgorithm.rsaEncryptionOAEPSHA1
        guard let encryptedData = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, nil) else {
            throw SessionError.invalidData
        }
        return encryptedData as Data
    }
}
