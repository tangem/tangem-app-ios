
//
//  CARD.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

public protocol ApduSerializable: class {
    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype CommandResponse: TlvCodable
    
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

public protocol Command: CardSessionRunnable, ApduSerializable {}

extension Command {
    public func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        transieve(in: session, completion: completion)
    }
    
    /// Fix nfc issues with long-running commands and security delay for iPhone 7/7+. Card firmware 2.39
    /// 4 - Timeout setting for ping nfc-module
    func createTlvBuilder(legacyMode: Bool) -> TlvBuilder {
        return try! TlvBuilder().append(.legacyMode, value: 4)
    }
    
    func transieve(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        do {
            let commandApdu = try serialize(with: session.environment)
            session.send(apdu: commandApdu) {[weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let responseApdu):
                    do {
                        let responseData = try self.deserialize(with: session.environment, from: responseApdu)
                        completion(.success(responseData))
                    } catch {
                        completion(.failure(error.toTaskError()))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error.toTaskError()))
        }
    }
}

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
