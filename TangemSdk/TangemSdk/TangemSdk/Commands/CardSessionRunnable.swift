
//
//  CARD.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

public protocol AnyCardSessionRunnable {}

/// Abstract class for all Tangem card commands.
public protocol CardSessionRunnable: AnyCardSessionRunnable {
    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype CommandResponse: TlvCodable
    
    func run(session: CommandTransiever, viewDelegate: CardManagerDelegate, environment: CardEnvironment, completion: @escaping CompletionResult<CommandResponse>)
}

@available(iOS 13.0, *)
public protocol CardSessionPreflightRunnable: AnyCardSessionRunnable {
    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype CommandResponse: TlvCodable
    
    func run(session: CommandTransiever, viewDelegate: CardManagerDelegate, environment: CardEnvironment, currentCard: Card, completion: @escaping CompletionResult<CommandResponse>)
}

public protocol ApduSerializable {
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

public extension ApduSerializable {
    /// Fix nfc issues with long-running commands and security delay for iPhone 7/7+. Card firmware 2.39
    /// 4 - Timeout setting for ping nfc-module
    func createTlvBuilder(legacyMode: Bool) -> TlvBuilder {
        return try! TlvBuilder().append(.legacyMode, value: 4)
    }
}

public protocol Command: CardSessionRunnable, ApduSerializable {}
public protocol PreflightCommand: CardSessionPreflightRunnable, ApduSerializable {}

public extension Command {
    func run(session: CommandTransiever, viewDelegate: CardManagerDelegate, environment: CardEnvironment, completion: @escaping CompletionResult<CommandResponse>) {
        session.sendCommand(self, environment: environment, completion: completion)
    }
}

public extension PreflightCommand {
    func run(session: CommandTransiever, viewDelegate: CardManagerDelegate, environment: CardEnvironment, currentCard: Card, completion: @escaping CompletionResult<CommandResponse>) {
        session.sendCommand(self, environment: environment, completion: completion)
    }
}

public protocol TlvCodable: Codable, CustomStringConvertible {}

extension TlvCodable {
    public var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = (try? encoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }
}
