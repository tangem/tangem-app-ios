//
//  SignCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Response for `SignCommand`.
public struct SignResponse: TlvCodable {
    /// CID, Unique Tangem card ID number
    public let cardId: String
    /// Signed hashes (array of resulting signatures)
    public let signature: Data
    /// Remaining number of sign operations before the wallet will stop signing transactions.
    public let walletRemainingSignatures: Int
    /// Total number of signed single hashes returned by the card in sign command responses.
    public let walletSignedHashes: Int
}

/// Signs transaction hashes using a wallet private key, stored on the card.
@available(iOS 13.0, *)
public final class SignCommand: Command {
    public typealias CommandResponse = SignResponse
    
    private let hashes: [Data]
    private var responces: [SignResponse] = []
    private var currentChunk = 0
    private lazy var chunkSize: Int = {
        return NfcUtils.isPoorNfcQualityDevice ? 2 : 10
    }()
    private lazy var numberOfChunks: Int = {
        return stride(from: 0, to: hashes.count, by: chunkSize).underestimatedCount
    }()
    
    /// Command initializer
    /// - Parameters:
    ///   - hashes: Array of transaction hashes.
    public init(hashes: [Data]) {
        self.hashes = hashes
    }
    
    deinit {
        print("SignCommand deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<SignResponse>) {
        guard hashes.count > 0 else {
            completion(.failure(.emptyHashes))
            return
        }
    
        let isLinkedTerminalSupported = session.environment.card?.isLinkedTerminalSupported ?? false
        let hasTerminalKeys = session.environment.terminalKeys != nil
        let delay = session.environment.card?.pauseBeforePin2 ?? 3000
        let hasEnoughDelay = (delay * numberOfChunks) <= 5000
        guard hashes.count <= chunkSize || (isLinkedTerminalSupported && hasTerminalKeys) || hasEnoughDelay else {
            completion(.failure(.tooMuchHashesInOneTransaction))
            return
        }
        
        guard !hashes.contains(where: { $0.count != hashes.first!.count }) else {
            completion(.failure(.hashSizeMustBeEqual))
            return
        }
        
        sign(in: session, completion: completion)
    }
    
    func sign(in session: CardSession, completion: @escaping CompletionResult<SignResponse>) {
        if currentChunk == numberOfChunks {
            let lastResponse = responces.last!
            let finalResponse = SignResponse(cardId: lastResponse.cardId,
                                             signature: Data(responces.map{ $0.signature }.joined()),
                                             walletRemainingSignatures: lastResponse.walletRemainingSignatures,
                                             walletSignedHashes: lastResponse.walletSignedHashes)
            
            completion(.success(finalResponse))
            return
        }
        
        if numberOfChunks > 1 {
            session.viewDelegate.showAlertMessage("Signing part \(currentChunk + 1) of \(numberOfChunks)")
        }
        
        transieve(in: session) { result in
            switch result {
            case .success(let response):
                self.responces.append(response)
                self.currentChunk += 1
                self.sign(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    public func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let flattenHashes = Data(hashes[getChunk()].joined())
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1)
            .append(.pin2, value: environment.pin2)
            .append(.cardId, value: environment.card?.cardId)
            .append(.transactionOutHashSize, value: hashes.first!.count)
            .append(.transactionOutHash, value: flattenHashes)
        
        /**
         * Application can optionally submit a public key Terminal_PublicKey in [SignCommand].
         * Submitted key is stored by the Tangem card if it differs from a previous submitted Terminal_PublicKey.
         * The Tangem card will not enforce security delay if [SignCommand] will be called with
         * TerminalTransactionSignature parameter containing a correct signature of raw data to be signed made with TerminalPrivateKey
         * (this key should be generated and securily stored by the application).
         * COS version 2.30 and later.
         */
        let isLinkedTerminalSupported = environment.card?.isLinkedTerminalSupported ?? false
        if let keys = environment.terminalKeys, isLinkedTerminalSupported,
            let signedData = Secp256k1Utils.sign(flattenHashes, with: keys.privateKey) {
            try tlvBuilder
                .append(.terminalTransactionSignature, value: signedData)
                .append(.terminalPublicKey, value: keys.publicKey)
        }
        
        return CommandApdu(.sign, tlv: tlvBuilder.serialize())
    }
    
    public func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SignResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw SessionError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return SignResponse(
            cardId: try decoder.decode(.cardId),
            signature: try decoder.decode(.walletSignature),
            walletRemainingSignatures: try decoder.decode(.walletRemainingSignatures),
            walletSignedHashes: try decoder.decode(.walletSignedHashes))
    }
    
    public func tryHandleError(_ error: SessionError) -> SessionError? {
        if error == SessionError.unknownStatus {
            return SessionError.nfcStuck
        } else { return error }
    }
    
    private func getChunk() -> Range<Int> {
        let from = currentChunk * chunkSize
        let to = min(from + chunkSize, hashes.count)
        return from..<to
    }
}
