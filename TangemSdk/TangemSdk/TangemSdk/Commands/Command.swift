
//
//  CARD.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

protocol ApduSerializable {
    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype CommandResponse: ResponseCodable
    
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

extension ApduSerializable {
    /// Fix nfc issues with long-running commands and security delay for iPhone 7/7+. Card firmware 2.39
    /// 4 - Timeout setting for ping nfc-module
    func createTlvBuilder(legacyMode: Bool) -> TlvBuilder {
        let builder = TlvBuilder()
        if legacyMode {
            try! builder.append(.legacyMode, value: 4)
        }
        return builder
    }
}

/// The basic protocol for card commands
@available(iOS 13.0, *)
protocol Command: ApduSerializable, CardSessionRunnable {
    func performPreCheck(_ card: Card) -> TangemSdkError?
    func performAfterCheck(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError?
}

@available(iOS 13.0, *)
extension Command {    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        transieve(in: session, completion: completion)
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        return nil
    }
    
    func performAfterCheck(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError? {
        return error
    }
    
    func transieve(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        if needPreflightRead && session.environment.card == nil {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if session.environment.handleErrors, let card = session.environment.card {
            if let error = performPreCheck(card) {
                completion(.failure(error))
                return
            }
        }
        
        do {
            let commandApdu = try serialize(with: session.environment)
            transieve(apdu: commandApdu, in: session) { result in
                switch result {
                case .success(let responseApdu):
                    do {
                        let responseData = try self.deserialize(with: session.environment, from: responseApdu)
                        completion(.success(responseData))
                    } catch {
                        completion(.failure(error.toTangemSdkError()))
                    }
                case .failure(let error):
                    if session.environment.handleErrors, let handledError = self.performAfterCheck(session.environment.card, error) {
                        completion(.failure(handledError))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }
        
    private func transieve(apdu: CommandApdu, in session: CardSession, completion: @escaping CompletionResult<ResponseApdu>) {
        print("transieve: \(Instruction(rawValue: apdu.ins)!)")
        session.send(apdu: apdu) { result in
            switch result {
            case .success(let responseApdu):
                switch responseApdu.statusWord {
                case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed:
                    completion(.success(responseApdu))
                case .needPause:
                    if let securityDelayResponse = self.deserializeSecurityDelay(with: session.environment, from: responseApdu) {
                        session.viewDelegate.showSecurityDelay(remainingMilliseconds: securityDelayResponse.remainingMilliseconds)
                        if securityDelayResponse.saveToFlash && session.environment.encryptionMode == .none {
                            session.restartPolling()
                        } else {
                            self.transieve(apdu: apdu, in: session, completion: completion)
                        }
                    }
                    
                case .needEcryption:
                    switch session.environment.encryptionMode {
                    case .none:
                        print("try fast encryption")
                        session.environment.encryptionKey = nil
                        session.environment.encryptionMode = .fast
                    case .fast:
                        print("try strong encryption")
                        session.environment.encryptionKey = nil
                        session.environment.encryptionMode = .strong
                    case .strong:
                        break
                    }
                    self.transieve(apdu: apdu, in: session, completion: completion)
                default:
                    completion(.failure(responseApdu.statusWord.toTangemSdkError() ?? .unknownError))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
public protocol ResponseCodable: Codable, CustomStringConvertible {}

extension ResponseCodable {
    public var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
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
