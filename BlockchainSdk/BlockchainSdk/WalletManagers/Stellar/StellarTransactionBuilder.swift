//
//  Stellart=TransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import Combine


class StellarTransactionBuilder {
    public var sequence: Int64?
    var useTimebounds = true
    
    private let stellarSdk: StellarSDK
    private let walletPublicKey: Data
    private let isTestnet: Bool
    
    init(stellarSdk: StellarSDK, walletPublicKey: Data, isTestnet: Bool) {
        self.stellarSdk = stellarSdk
        self.walletPublicKey = walletPublicKey
        self.isTestnet = isTestnet
    }
    
    @available(iOS 13.0, *)
    public func buildForSign(transaction: Transaction) -> AnyPublisher<(hash: Data, transaction: stellarsdk.TransactionXDR), Error> {
        let future = Future<(hash: Data, transaction: stellarsdk.TransactionXDR), Error> {[weak self] promise in
            self?.buildForSign(transaction: transaction, completion: { result in
                switch result {
                case .success(let response):
                    promise(.success(response))
                case .failure(let error):
                    promise(.failure(error))
                }
            })
        }
        return AnyPublisher(future)
    }
    
    @available(iOS 13.0, *)
    public func buildForSign(transaction: Transaction, completion: @escaping (Result<(hash: Data, transaction: stellarsdk.TransactionXDR), Error>) -> Void ) {
        guard let destinationKeyPair = try? KeyPair(accountId: transaction.destinationAddress),
            let sourceKeyPair = try? KeyPair(accountId: transaction.sourceAddress) else {
                completion(.failure(StellarError.failedToBuildTransaction))
                return
        }
        
        if transaction.amount.type == .coin {
            checkIfAccountCreated(transaction.destinationAddress) { [weak self] isCreated in
                let operation = isCreated ? PaymentOperation(sourceAccount: nil,
                                                             destination: destinationKeyPair,
                                                             asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                             amount: transaction.amount.value ) :
                    CreateAccountOperation(destination: destinationKeyPair, startBalance: transaction.amount.value)
                
                self?.serializeOperation(operation, sourceKeyPair: sourceKeyPair, completion: completion)
            }
        } else if transaction.amount.type == .token {
            guard let contractAddress = transaction.contractAddress, let keyPair = try? KeyPair(accountId: contractAddress),
                let asset = createNonNativeAsset(code: transaction.amount.currencySymbol, issuer: keyPair) else {
                    completion(.failure(StellarError.failedToBuildTransaction))
                    return
            }
            
            if  transaction.amount.value > 0 {
                 checkIfAccountCreated(transaction.destinationAddress) { [weak self] isCreated in
                    if !isCreated {
                        completion(.failure(StellarError.failedToBuildTransaction)) // [REDACTED_TODO_COMMENT]
                        return
                    }
                    
                   let operation = PaymentOperation(sourceAccount: sourceKeyPair,
                                                                destination: destinationKeyPair,
                                                                asset: asset,
                                                                amount: transaction.amount.value)
                    
                self?.serializeOperation(operation, sourceKeyPair: sourceKeyPair, completion: completion)
                    
                }
                
                
               
            } else {
                let operation = ChangeTrustOperation(sourceAccount: sourceKeyPair, asset: asset, limit: Decimal(string: "900000000000.0000000"))
                serializeOperation(operation, sourceKeyPair: sourceKeyPair, completion: completion)
            }
        }
        assertionFailure("unsuported amount type")
       completion(.failure(StellarError.failedToBuildTransaction))
    }
    
    @available(iOS 13.0, *)
    public func buildForSend(signature: Data, transaction: TransactionXDR) -> String? {
        var transaction = transaction
        var publicKeyData = walletPublicKey
        let hint = Data(bytes: &publicKeyData, count: publicKeyData.count).suffix(4)
        let decoratedSignature = DecoratedSignatureXDR(hint: WrappedData4(hint), signature: signature)
        transaction.addSignature(signature: decoratedSignature)
        let envelope = try? transaction.encodedEnvelope()
        return envelope
    }
    
    
    private func createNonNativeAsset(code: String, issuer: KeyPair) -> Asset? {
        if code.count >= 1 && code.count <= 4 {
            return Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: code, issuer: issuer)
        } else if code.count >= 5 && code.count <= 12 {
            return Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: code, issuer: issuer)
        } else {
            return nil
        }
    }
    
    private func checkIfAccountCreated(_ address: String, completion: @escaping (Bool) -> Void) {
        stellarSdk.accounts.getAccountDetails(accountId: address) { response -> (Void) in
            switch response {
            case .success(_):
                completion(true)
            case .failure(_):
                completion(false)
            }
        }
    }
    
    private func serializeOperation(_ operation: stellarsdk.Operation, sourceKeyPair: KeyPair, completion: @escaping (Result<(hash: Data, transaction: stellarsdk.TransactionXDR), Error>) -> Void ) {
        guard let xdrOperation = try? operation.toXDR(),
            let seqNumber = sequence else {
                completion(.failure(StellarError.failedToBuildTransaction))
                return
        }
        
        let currentTime = Date().timeIntervalSince1970
        let minTime = currentTime - 60.0
        let maxTime = currentTime + 60.0
        
        let tx = TransactionXDR(sourceAccount: sourceKeyPair.publicKey,
                                seqNum: seqNumber + 1,
                                timeBounds: useTimebounds ? TimeBoundsXDR(minTime: UInt64(minTime), maxTime: UInt64(maxTime)): nil,
                                memo: Memo.text("").toXDR(),
                                operations: [xdrOperation])
        
        let network = isTestnet ? Network.testnet : Network.public
        guard let hash = try? tx.hash(network: network) else {
            completion(.failure(StellarError.failedToBuildTransaction))
            return
        }
        
        completion(.success((hash, tx)))
    }
}
