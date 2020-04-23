
//
//  CARD.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

/// The basic protocol for card commands
public protocol Command: CardSessionRunnable, ErrorHandler {
    /// Serializes data into an array of `Tlv`, then creates `CommandApdu` with this data.
    /// - Parameter environment: `SessionEnvironment` of the current card
    /// - Returns: Command data that can be converted to `NFCISO7816APDU` with appropriate initializer
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu
    
    /// Deserializes data, received from a card and stored in `ResponseApdu`  into an array of `Tlv`. Then this method maps it into a `CommandResponse`.
    /// - Parameters:
    ///   - environment: `SessionEnvironment` of the current card
    ///   - apdu: Received data
    /// - Returns: Card response, converted to a `CommandResponse` of a type `T`.
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> CommandResponse
}

extension Command {
    public func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        transieve(in: session, completion: completion)
    }
    
    public func tryHandleError(_ error: SessionError) -> SessionError? {
        return error
    }
    
    func transieve(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        do {
            let commandApdu = try serialize(with: session.environment)
            transieve(apdu: commandApdu, in: session) { result in
                switch result {
                case .success(let responseApdu):
                    do {
                        let responseData = try self.deserialize(with: session.environment, from: responseApdu)
                        completion(.success(responseData))
                    } catch {
                        completion(.failure(error.toSessionError()))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error.toSessionError()))
        }
    }
    
    func transieve(apdu: CommandApdu, in session: CardSession, completion: @escaping CompletionResult<ResponseApdu>) {
        session.send(apdu: apdu) {commandResponse in
            switch commandResponse {
            case .success(let responseApdu):
                switch responseApdu.statusWord {
                case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed:
                    completion(.success(responseApdu))
                case .needPause:
                    if let securityDelayResponse = self.deserializeSecurityDelay(with: session.environment, from: responseApdu) {
                        session.viewDelegate.showSecurityDelay(remainingMilliseconds: securityDelayResponse.remainingMilliseconds)
                        if securityDelayResponse.saveToFlash {
                            session.restartPolling()
                        }
                    }
                    self.transieve(apdu: apdu, in: session, completion: completion)
                default:
                    if let error = responseApdu.statusWord.toSessionError() {
                        if let newError = self.tryHandleError(error) {
                            completion(.failure(newError))
                        }
                    } else {
                        completion(.failure(.unknownError))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Fix nfc issues with long-running commands and security delay for iPhone 7/7+. Card firmware 2.39
    /// 4 - Timeout setting for ping nfc-module
    func createTlvBuilder(legacyMode: Bool) -> TlvBuilder {
        let builder = TlvBuilder()
        if legacyMode {
            try! builder.append(.legacyMode, value: 4)
        }
        return builder
    }
    
    
    /// Helper method to parse security delay information received from a card.
    /// - Returns: Remaining security delay in milliseconds.
    private func deserializeSecurityDelay(with environment: SessionEnvironment, from responseApdu: ResponseApdu) -> (remainingMilliseconds: Int, saveToFlash: Bool)? {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey),
            let remainingMilliseconds = tlv.value(for: .pause)?.toInt() else {
                return nil
        }
        
        let saveToFlash = tlv.contains(tag: .flash)
        return (remainingMilliseconds, saveToFlash)
    }
}

/// The basic protocol for command response
public protocol TlvCodable: Codable, CustomStringConvertible {}

extension TlvCodable {
    public var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dataEncodingStrategy = .custom{ data, encoder in
            var container = encoder.singleValueContainer()
            return try container.encode(data.asHexString())
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .medium
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        
        let data = (try? encoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }
}


public protocol ErrorHandler {
    func tryHandleError(_ error: SessionError) -> SessionError?
}
