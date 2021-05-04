//
//  VerifyCardCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


public enum VerifyCardState: String, Codable {
    case offline
    case online
}


/// Deserialized response from the Tangem card after `VerifyCardResponseCommand`.
public struct VerifyCardResponse: JSONStringConvertible {
    public let cardId: String
    public let verificationState: VerifyCardState?
    public let artworkInfo: ArtworkInfo?
    public let cardPublicKey: Data
    
    let salt: Data
    let cardSignature: Data
    
    internal init(cardId: String, salt: Data, cardSignature: Data, cardPublicKey: Data, verificationState: VerifyCardState? = nil, artworkInfo: ArtworkInfo? = nil) {
        self.cardId = cardId
        self.verificationState = verificationState
        self.artworkInfo = artworkInfo
        self.salt = salt
        self.cardSignature = cardSignature
        self.cardPublicKey = cardPublicKey
    }
    
    func verify(publicKey: Data, challenge: Data) -> Bool? {
        return CryptoUtils.verify(curve: .secp256k1,
                                  publicKey: publicKey,
                                  message: challenge + salt,
                                  signature: cardSignature)
        
    }
}

public class VerifyCardCommand: Command {
    public typealias CommandResponse = VerifyCardResponse
    
    private var challenge: Data? = nil

    public init() {
        self.challenge = try? CryptoUtils.generateRandomBytes(count: 16)
    }
    
    deinit {
        Log.debug("VerifyCardCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if let status = card.status, status == .notPersonalized {
            return .notPersonalized
        }
        
        if card.isActivated {
            return .notActivated
        }
        
        return nil
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<VerifyCardResponse>) {
        guard let cardPublicKey = session.environment.card?.cardPublicKey else {
            completion(.failure(.cardError))
            return
        }
        
        guard let challenge = self.challenge else {
            completion(.failure(.failedToGenerateRandomSequence))
            return
        }
        
        transieve(in: session) { result in
            switch result {
            case .success(let response):
                guard let verified = response.verify(publicKey: cardPublicKey, challenge: challenge) else {
                    completion(.failure(.cryptoUtilsError))
                    return
                }
                
                if !verified {
                    completion(.failure(.cardVerificationFailed))
                    return
                }
                
                let response = VerifyCardResponse(cardId: response.cardId,
                                                  salt: response.salt,
                                                  cardSignature: response.cardSignature,
                                                  cardPublicKey: cardPublicKey,
                                                  verificationState: .offline)
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.challenge, value: challenge)
        
        return CommandApdu(.verifyCard, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> VerifyCardResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return VerifyCardResponse(
            cardId: try decoder.decode(.cardId),
            salt: try decoder.decode(.salt),
            cardSignature: try decoder.decode(.cardSignature),
            cardPublicKey: Data())
    }
}
