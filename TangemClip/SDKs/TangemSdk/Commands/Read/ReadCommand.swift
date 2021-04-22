//
//  ReadCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public typealias ReadResponse = Card

/// This command receives from the Tangem Card all the data about the card and the wallet,
///  including unique card number (CID or cardId) that has to be submitted while calling all other commands.
final class ReadCommand: Command {
    typealias CommandResponse = ReadResponse
    
    var needPreflightRead: Bool {
        return false
    }
	
    deinit {
        Log.debug("ReadCommand deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<ReadResponse>) {
        transieve(in: session) { result in
            switch result {
            case .success(let readResponse):
                session.environment.card = readResponse
                completion(.success(readResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
            return .pin1Required
        }
        
        return error
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        /// `SessionEnvironment` stores the pin1 value. If no pin1 value was set, it will contain
        /// default value of ‘000000’.
        /// In order to obtain card’s data, [ReadCommand] should use the correct pin 1 value.
        /// The card will not respond if wrong pin 1 has been submitted.
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.interactionMode, value: ReadMode.readCard)
        if let keys = environment.terminalKeys {
            try tlvBuilder.append(.terminalPublicKey, value: keys.publicKey)
        }
        
        
        return CommandApdu(.read, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadResponse {
		let readResponse = try CardDeserializer.deserialize(with: environment, from: apdu)
        
		return readResponse
    }
}
