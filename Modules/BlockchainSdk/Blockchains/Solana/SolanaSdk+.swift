//
//  SolanaSdk+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SolanaSwift
import TangemNetworkUtils

extension Api {
    func getFees(
        commitment: Commitment? = nil
    ) -> AnyPublisher<SolanaSwift.Fee, Error> {
        Deferred { [weak self] in
            Future { promise in
                guard let self = self else {
                    promise(.failure(BlockchainSdkError.empty))
                    return
                }

                self.getFees(commitment: commitment) { result in
                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let fee):
                        promise(.success(fee))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getFeeForMessage(_ message: String) -> AnyPublisher<FeeForMessageResult, Error> {
        Deferred { [weak self] in
            Future { promise in
                guard let self else {
                    promise(.failure(BlockchainSdkError.empty))
                    return
                }

                self.getFeeForMessage(message: message) { result in
                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let feeForMessage):
                        promise(.success(feeForMessage))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getMinimumBalanceForRentExemption(
        dataLength: UInt64,
        commitment: Commitment? = nil
    ) -> AnyPublisher<UInt64, Error> {
        Deferred { [weak self] in
            Future { promise in
                guard let self = self else {
                    promise(.failure(BlockchainSdkError.empty))
                    return
                }

                self.getMinimumBalanceForRentExemption(
                    dataLength: dataLength,
                    commitment: commitment
                ) { result in
                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let fee):
                        promise(.success(fee))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getAccountInfo<T: BufferLayout>(account: String, decodedTo: T.Type) -> AnyPublisher<BufferInfo<T>, Error> {
        Deferred { [weak self] in
            Future { promise in
                guard let self = self else {
                    promise(.failure(BlockchainSdkError.empty))
                    return
                }

                self.getAccountInfo(account: account, decodedTo: T.self) { result in
                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let fee):
                        promise(.success(fee))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getTokenAccountsByOwner<T: Decodable>(
        pubkey: String,
        mint: String? = nil,
        programId: String? = nil,
        configs: RequestConfiguration? = nil
    ) -> AnyPublisher<[T], Error> {
        Deferred { [weak self] in
            Future { promise in
                guard let self = self else {
                    promise(.failure(BlockchainSdkError.empty))
                    return
                }

                self.getTokenAccountsByOwner(pubkey: pubkey, mint: mint, programId: programId, configs: configs) {
                    (result: Result<[T], Error>) in
                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let accounts):
                        promise(.success(accounts))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getSignatureStatuses(pubkeys: [String], configs: RequestConfiguration? = nil) -> AnyPublisher<[SignatureStatus?], Error> {
        Deferred { [weak self] in
            Future { promise in
                guard let self = self else {
                    promise(.failure(BlockchainSdkError.empty))
                    return
                }

                self.getSignatureStatuses(pubkeys: pubkeys, configs: configs) { result in
                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let statuses):
                        promise(.success(statuses))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func sendTransaction(
        serializedTransaction: String,
        startSendingTimestamp: Date = Date(),
        configs: RequestConfiguration = RequestConfiguration(encoding: "base64", maxRetries: 12)!
    ) -> AnyPublisher<TransactionID, Error> {
        Deferred { [weak self] in
            Future { promise in
                guard let self = self else {
                    promise(.failure(BlockchainSdkError.empty))
                    return
                }

                self.sendTransaction(
                    serializedTransaction: serializedTransaction,
                    configs: configs,
                    startSendingTimestamp: startSendingTimestamp
                ) { result in
                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let statuses):
                        promise(.success(statuses))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension Action {
    func serializeMessage(
        to destination: String,
        amount: UInt64,
        computeUnitLimit: UInt32?,
        computeUnitPrice: UInt64?,
        allowUnfundedRecipient: Bool = false,
        allowCompoundRecipient: Bool = false,
        fromPublicKey: PublicKey
    ) -> AnyPublisher<(String, Date), Error> {
        Deferred { [weak self] in
            Future { promise in
                guard let self else {
                    promise(.failure(BlockchainSdkError.empty))
                    return
                }

                self.serializeMessage(
                    to: destination,
                    amount: amount,
                    computeUnitLimit: computeUnitLimit,
                    computeUnitPrice: computeUnitPrice,
                    allowUnfundedRecipient: allowUnfundedRecipient,
                    allowCompoundRecipient: allowCompoundRecipient,
                    fromPublicKey: fromPublicKey
                ) { result in
                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let message):
                        promise(.success(message))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func sendSOL(
        to destination: String,
        amount: UInt64,
        computeUnitLimit: UInt32?,
        computeUnitPrice: UInt64?,
        allowUnfundedRecipient: Bool = false,
        signer: Signer
    ) -> AnyPublisher<TransactionID, Error> {
        Deferred { [weak self] in
            Future { promise in
                guard let self = self else {
                    promise(.failure(BlockchainSdkError.empty))
                    return
                }

                self.sendSOL(
                    to: destination,
                    amount: amount,
                    computeUnitLimit: computeUnitLimit,
                    computeUnitPrice: computeUnitPrice,
                    allowUnfundedRecipient: allowUnfundedRecipient,
                    signer: signer
                ) { result in
                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let transactionID):
                        promise(.success(transactionID))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func sendSPLTokens(
        mintAddress: String,
        tokenProgramId: PublicKey,
        decimals: Decimals,
        from fromPublicKey: String,
        to destinationAddress: String,
        amount: UInt64,
        computeUnitLimit: UInt32?,
        computeUnitPrice: UInt64?,
        allowUnfundedRecipient: Bool = false,
        signer: Signer
    ) -> AnyPublisher<TransactionID, Error> {
        Deferred { [weak self] in
            Future { promise in
                guard let self = self else {
                    promise(.failure(BlockchainSdkError.empty))
                    return
                }

                self.sendSPLTokens(
                    mintAddress: mintAddress,
                    tokenProgramId: tokenProgramId,
                    decimals: decimals,
                    from: fromPublicKey,
                    to: destinationAddress,
                    amount: amount,
                    computeUnitLimit: computeUnitLimit,
                    computeUnitPrice: computeUnitPrice,
                    allowUnfundedRecipient: allowUnfundedRecipient,
                    signer: signer
                ) { result in
                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let transactionID):
                        promise(.success(transactionID))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func checkTokenAddressExists(
        mintAddress: String,
        tokenProgramId: PublicKey,
        destinationAddress: String,
        allowUnfundedRecipient: Bool
    ) -> AnyPublisher<Bool, Error> {
        Deferred { [weak self] in
            Future { promise in
                guard let self = self else {
                    promise(.failure(BlockchainSdkError.empty))
                    return
                }

                self.findSPLTokenDestinationAddress(
                    mintAddress: mintAddress,
                    tokenProgramId: tokenProgramId,
                    destinationAddress: destinationAddress,
                    allowUnfundedRecipient: allowUnfundedRecipient
                ) { result in
                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let response):
                        promise(.success(!response.isUnregisteredAsocciatedToken))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
