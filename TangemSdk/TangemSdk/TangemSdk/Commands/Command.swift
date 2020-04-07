
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
public protocol Command: CardSessionRunnable {
    /// Serializes data into an array of `Tlv`, then creates `CommandApdu` with this data.
    /// - Parameter environment: `CardEnvironment` of the current card
    /// - Returns: Command data that can be converted to `NFCISO7816APDU` with appropriate initializer
    func serialize(with environment: CardEnvironment) throws -> CommandApdu
    
    /// Deserializes data, received from a card and stored in `ResponseApdu`  into an array of `Tlv`. Then this method maps it into a `CommandResponse`.
    /// - Parameters:
    ///   - environment: `CardEnvironment` of the current card
    ///   - apdu: Received data
    /// - Returns: Card response, converted to a `CommandResponse` of a type `T`.
    func deserialize(with environment: CardEnvironment, from apdu: ResponseApdu) throws -> CommandResponse
}

extension Command {
    public func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        transieve(in: session, completion: completion)
    }
    
    func transieve(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        do {
            let commandApdu = try serialize(with: session.environment)
            transieve(in: session, apdu: commandApdu) { result in
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
    
    func transieve(in session: CardSession, apdu: CommandApdu, completion: @escaping CompletionResult<ResponseApdu>) {
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
                    self.transieve(in: session, apdu: apdu, completion: completion)
                default:
                    if let error = responseApdu.statusWord.toSessionError() {
                        if !self.tryHandleError(error) {
                            completion(.failure(error))
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
    
    func tryHandleError(_ error: SessionError) -> Bool {
        return false
    }
    
    /// Fix nfc issues with long-running commands and security delay for iPhone 7/7+. Card firmware 2.39
    /// 4 - Timeout setting for ping nfc-module
    func createTlvBuilder(legacyMode: Bool) -> TlvBuilder {
        return try! TlvBuilder().append(.legacyMode, value: 4)
    }
    
    
    /// Helper method to parse security delay information received from a card.
    /// - Returns: Remaining security delay in milliseconds.
    private func deserializeSecurityDelay(with environment: CardEnvironment, from responseApdu: ResponseApdu) -> (remainingMilliseconds: Int, saveToFlash: Bool)? {
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
        dateFormatter.dateStyle = .medium
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        
        let data = (try? encoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }
}
