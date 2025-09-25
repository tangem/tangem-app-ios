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
    private let sessionId: String
    private let secretKey: String

    private var cancellable: Cancellable?
    private var cardDetailsExposureTask: Task<Void, Never>?

    init(lastFourDigits: String, customerInfoManagementService: any CustomerInfoManagementService) {
        cardDetailsData = .hidden(lastFourDigits: lastFourDigits)
        self.customerInfoManagementService = customerInfoManagementService

        let session = try! SessionCrypto.generateSessionId(environment: .dev)
        sessionId = session.sessionId
        secretKey = session.secretKey

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
        let cardDetails = try! await customerInfoManagementService.getCardDetails(sessionId: sessionId)

        let decryptedPan = try! SessionCrypto.decryptSecret(
            base64Secret: cardDetails.pan.secret,
            base64Iv: cardDetails.pan.iv,
            secretKey: secretKey
        )

        let decryptedCVV = try SessionCrypto.decryptSecret(
            base64Secret: cardDetails.cvv.secret,
            base64Iv: cardDetails.cvv.iv,
            secretKey: secretKey
        )

        return TangemPayCardDetailsData(
            number: decryptedPan,
            expirationDate: "\(cardDetails.expirationMonth)/\(cardDetails.expirationYear)",
            cvc: decryptedCVV
        )
    }
}

private extension TangemPayCardDetailsViewModel {
    enum Constants {
        static let cardDetailsVisibilityPeriodInSeconds: TimeInterval = 30
    }
}

import CryptoKit
import Security

public enum EncryptionUtils {
    public enum EncryptionError: Error {
        case encryptionFailed
        case invalidKeyData
    }

    public struct EncryptedData {
        public let ciphertext: Data
        public let tag: Data
        public let nonce: Data

        public init(ciphertext: Data, tag: Data, nonce: Data) {
            self.ciphertext = ciphertext
            self.tag = tag
            self.nonce = nonce
        }
    }

    public static func encryptAESGCM(plaintext: String, secretKey: String) throws -> EncryptedData {
        guard let plaintextData = plaintext.data(using: .utf8),
              let secretKeyData = Data(hex: secretKey) else {
            throw EncryptionError.invalidKeyData
        }

        let key = SymmetricKey(data: secretKeyData)
        let nonce = AES.GCM.Nonce()

        do {
            let sealedBox = try AES.GCM.seal(plaintextData, using: key, nonce: nonce)
            return EncryptedData(
                ciphertext: sealedBox.ciphertext,
                tag: sealedBox.tag,
                nonce: Data(nonce)
            )
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }

    public static func encryptAESGCM(plaintext: String, secretKey: String, nonce: Data) throws -> EncryptedData {
        guard let plaintextData = plaintext.data(using: .utf8),
              let secretKeyData = Data(hex: secretKey) else {
            throw EncryptionError.invalidKeyData
        }

        let key = SymmetricKey(data: secretKeyData)

        do {
            let gcmNonce = try AES.GCM.Nonce(data: nonce)
            let sealedBox = try AES.GCM.seal(plaintextData, using: key, nonce: gcmNonce)
            return EncryptedData(
                ciphertext: sealedBox.ciphertext,
                tag: sealedBox.tag,
                nonce: nonce
            )
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }

    public static func formatForDecryption(encryptedData: EncryptedData) -> (base64Secret: String, base64Iv: String) {
        var combinedData = Data()
        combinedData.append(encryptedData.ciphertext)
        combinedData.append(encryptedData.tag)

        let base64Secret = combinedData.base64EncodedString()
        let base64Iv = encryptedData.nonce.base64EncodedString()

        return (base64Secret, base64Iv)
    }
}

public enum SessionCrypto {
    public enum Environment {
        case dev
        case prod

        var keyFileName: String {
            switch self {
            case .dev:
                return "dev_public_key.pem"
            case .prod:
                return "prod_public_key.pem"
            }
        }
    }

    public struct SessionResult {
        public let secretKey: String
        public let sessionId: String

        public init(secretKey: String, sessionId: String) {
            self.secretKey = secretKey
            self.sessionId = sessionId
        }
    }

    public enum SessionCryptoError: Error {
        case pemRequired
        case secretMustBeHexString
        case base64SecretRequired
        case base64IvRequired
        case secretKeyMustBeHexString
        case invalidPEMFormat
        case encryptionFailed
        case decryptionFailed
        case resourceNotFound
        case invalidKeyData
    }

    public static func generateSessionId(pem: String, secret: String? = nil) throws -> SessionResult {
        guard !pem.isEmpty else {
            throw SessionCryptoError.pemRequired
        }

        if let secret = secret, !isHexString(secret) {
            throw SessionCryptoError.secretMustBeHexString
        }

        let secretKey = secret ?? UUID().uuidString.replacingOccurrences(of: "-", with: "")

        guard let secretKeyData = Data(hex: secretKey) else {
            throw SessionCryptoError.secretMustBeHexString
        }

        let secretKeyBase64 = secretKeyData.base64EncodedString()
        guard let secretKeyBase64Data = secretKeyBase64.data(using: .utf8) else {
            throw SessionCryptoError.encryptionFailed
        }

        let publicKey = try parsePublicKey(from: pem)
        let encryptedData = try encryptWithPublicKey(data: secretKeyBase64Data, publicKey: publicKey)
        let sessionId = encryptedData.base64EncodedString()

        return SessionResult(secretKey: secretKey, sessionId: sessionId)
    }

    public static func generateSessionId(environment: Environment, secret: String? = nil) throws -> SessionResult {
        let pem = try loadPublicKey(for: environment)
        return try generateSessionId(pem: pem, secret: secret)
    }

    public static func decryptSecret(base64Secret: String, base64Iv: String, secretKey: String) throws -> String {
        guard !base64Secret.isEmpty else {
            throw SessionCryptoError.base64SecretRequired
        }

        guard !base64Iv.isEmpty else {
            throw SessionCryptoError.base64IvRequired
        }

        guard !secretKey.isEmpty, isHexString(secretKey) else {
            throw SessionCryptoError.secretKeyMustBeHexString
        }

        guard let secretData = Data(base64Encoded: base64Secret),
              let ivData = Data(base64Encoded: base64Iv),
              let secretKeyData = Data(hex: secretKey) else {
            throw SessionCryptoError.decryptionFailed
        }

        // AES-GCM typically uses a 128-bit (16-byte) authentication tag
        let tagLength = 16

        guard secretData.count >= tagLength else {
            throw SessionCryptoError.decryptionFailed
        }

        let ciphertext = secretData.dropLast(tagLength)
        let authTag = secretData.suffix(tagLength)

        do {
            let symmetricKey = SymmetricKey(data: secretKeyData)
            let nonce = try AES.GCM.Nonce(data: ivData)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: authTag)
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)

            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                throw SessionCryptoError.decryptionFailed
            }

            return decryptedString.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw SessionCryptoError.decryptionFailed
        }
    }

    // MARK: - Private Helper Methods

    private static func isHexString(_ string: String) -> Bool {
        let hexRegex = "^[0-9A-Fa-f]+$"
        return NSPredicate(format: "SELF MATCHES %@", hexRegex).evaluate(with: string)
    }

    private static func loadPublicKey(for environment: Environment) throws -> String {
        guard let resourceURL = Bundle.main.url(forResource: environment.keyFileName.replacingOccurrences(of: ".pem", with: ""), withExtension: "pem") else {
            throw SessionCryptoError.resourceNotFound
        }

        do {
            return try String(contentsOf: resourceURL)
        } catch {
            throw SessionCryptoError.resourceNotFound
        }
    }

    private static func parsePublicKey(from pem: String) throws -> SecKey {
        let pemHeader = "-----BEGIN PUBLIC KEY-----"
        let pemFooter = "-----END PUBLIC KEY-----"

        let pemBody = pem
            .replacingOccurrences(of: pemHeader, with: "")
            .replacingOccurrences(of: pemFooter, with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let keyData = Data(base64Encoded: pemBody) else {
            throw SessionCryptoError.invalidPEMFormat
        }

        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
        ]

        var error: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(keyData as CFData, keyAttributes as CFDictionary, &error) else {
            throw SessionCryptoError.invalidKeyData
        }

        return publicKey
    }

    private static func encryptWithPublicKey(data: Data, publicKey: SecKey) throws -> Data {
        let algorithm = SecKeyAlgorithm.rsaEncryptionOAEPSHA1

        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            throw SessionCryptoError.encryptionFailed
        }

        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, &error) else {
            throw SessionCryptoError.encryptionFailed
        }

        return encryptedData as Data
    }
}

// MARK: - Data Extension for Hex Conversion

private extension Data {
    init?(hex: String) {
        let length = hex.count
        guard length % 2 == 0 else { return nil }

        var data = Data()
        var index = hex.startIndex

        for _ in 0 ..< (length / 2) {
            let nextIndex = hex.index(index, offsetBy: 2)
            let hexByte = String(hex[index ..< nextIndex])
            guard let byte = UInt8(hexByte, radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }

        self = data
    }
}
