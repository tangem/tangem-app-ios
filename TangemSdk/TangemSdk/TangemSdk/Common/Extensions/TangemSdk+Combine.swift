//
//  ResponseApdu+Combine.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
extension ResponseApdu {
    func decryptPublisher(encryptionKey: Data?) -> AnyPublisher<ResponseApdu, TangemSdkError> {
        return Deferred {Future<ResponseApdu, TangemSdkError>() { promise in
            do {
                let decrypted = try self.decrypt(encryptionKey: encryptionKey)
                promise(.success(decrypted))
            } catch {
                let tangemSdkError = error.toTangemSdkError()
                let finalError: TangemSdkError = tangemSdkError == .unknownError ? .failedToDecryptApdu : tangemSdkError
                promise(.failure(finalError))
            }
            }}.eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension CommandApdu {
    func encryptPublisher(encryptionMode: EncryptionMode, encryptionKey: Data?) -> AnyPublisher<CommandApdu, TangemSdkError> {
        return Deferred {Future<CommandApdu, TangemSdkError>() { promise in
            do {
                let encrypted = try self.encrypt(encryptionMode: encryptionMode, encryptionKey: encryptionKey)
                promise(.success(encrypted))
            } catch {
                let tangemSdkError = error.toTangemSdkError()
                let finalError: TangemSdkError = tangemSdkError == .unknownError ? .failedToEncryptApdu : tangemSdkError
                promise(.failure(finalError))
            }
            }}.eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension NFCReader {
    /// Send apdu command to connected tag in Combine style
    /// - Parameter apdu: serialized apdu
    /// - Returns: ResponseApdu or NFCError otherwise
    func sendPublisher(apdu: CommandApdu) -> AnyPublisher<ResponseApdu, TangemSdkError> {
        return Deferred {Future<ResponseApdu, TangemSdkError>() { promise in
            self.send(apdu: apdu) { promise($0) }
            }}.eraseToAnyPublisher()
    }
}
