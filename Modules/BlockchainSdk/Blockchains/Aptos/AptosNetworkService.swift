//
//  AptosNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization

class AptosNetworkService: MultiNetworkProvider {
    // MARK: - Protperties

    let providers: [AptosNetworkProvider]

    var currentProviderIndex: Int = 0
    let blockchainName: String = Blockchain.aptos(curve: .ed25519_slip0010, testnet: false).displayName

    // MARK: - Init

    init(providers: [AptosNetworkProvider]) {
        self.providers = providers
    }

    // MARK: - Implementation

    func getAccount(address: String) -> AnyPublisher<AptosAccountInfo, Error> {
        getAccountInfo(address: address)
            .combineLatest(getCoinBalance(address: address))
            .withWeakCaptureOf(self)
            .tryMap { service, args -> AptosAccountInfo in
                let resources = args.0
                let balanceValue = args.1

                let accountJson = resources.first(where: { $0.type == Constants.accountKeyPrefix })

                if accountJson == nil, balanceValue == .zero {
                    throw BlockchainSdkError.noAccount(message: Localization.noAccountSendToCreate, amountToCreate: 0)
                }

                let sequenceNumber = Decimal(stringValue: accountJson?.data.sequenceNumber ?? "") ?? 0
                return AptosAccountInfo(sequenceNumber: sequenceNumber.int64Value, balance: balanceValue)
            }
            .eraseToAnyPublisher()
    }

    func getGasUnitPrice() -> AnyPublisher<UInt64, Error> {
        providerPublisher { provider in
            provider
                .getGasUnitPrice()
                .map { response in
                    response.gasEstimate
                }
                .eraseToAnyPublisher()
        }
    }

    func calculateUsedGasPriceUnit(info: AptosTransactionInfo) -> AnyPublisher<AptosFeeInfo, Error> {
        providerPublisher { [weak self] provider in
            guard let self = self else {
                return .anyFail(error: BlockchainSdkError.failedToGetFee)
            }

            let transactionBody = convertTransaction(info: info)

            return provider
                .calculateUsedGasPriceUnit(transactionBody: transactionBody)
                .withWeakCaptureOf(self)
                .tryMap { service, response in
                    guard let gasUsed = Decimal(stringValue: response.first?.gasUsed) else {
                        throw BlockchainSdkError.failedToGetFee
                    }

                    let maxGasAmount = gasUsed * Constants.successTransactionSafeFactor
                    let estimatedFeeDecimal = (Decimal(info.gasUnitPrice) * gasUsed * Constants.successTransactionSafeFactor)

                    return AptosFeeInfo(
                        value: estimatedFeeDecimal,
                        params: AptosFeeParams(
                            gasUnitPrice: info.gasUnitPrice,
                            maxGasAmount: maxGasAmount.roundedDecimalNumber.uint64Value
                        )
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func submitTransaction(data: Data) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            return provider
                .submitTransaction(data: data)
                .tryMap { response in
                    guard let transactionHash = response.hash else {
                        throw BlockchainSdkError.failedToParseNetworkResponse()
                    }

                    return transactionHash
                }
                .eraseToAnyPublisher()
        }
    }

    // MARK: - Private Implementation

    private func getAccountInfo(address: String) -> AnyPublisher<[AptosResponse.AccountResource], Error> {
        providerPublisher { provider in
            provider
                .getAccountResources(address: address)
                .eraseToAnyPublisher()
        }
    }

    private func getCoinBalance(address: String) -> AnyPublisher<Decimal, Error> {
        let payload = AptosRequest.View(
            function: Constants.aptosCoinBalanceFunction,
            type_arguments: [Constants.aptosCoinContract],
            arguments: [address]
        )

        return providerPublisher { provider in
            provider
                .getAccountView(payload: payload)
                .withWeakCaptureOf(self)
                .tryMap { service, response in
                    guard
                        let balanceResponse = response.first,
                        let balanceValue = Decimal(stringValue: balanceResponse)
                    else {
                        throw BlockchainSdkError.failedToParseNetworkResponse()
                    }

                    return balanceValue
                }
                .eraseToAnyPublisher()
        }
    }

    private func convertTransaction(info: AptosTransactionInfo) -> AptosRequest.TransactionBody {
        let transferPayload = AptosRequest.TransferPayload(
            type: Constants.transferPayloadType,
            function: Constants.transferPayloadFunction,
            typeArguments: [],
            arguments: [info.destinationAddress, String(info.amount)]
        )

        var signature: AptosRequest.Signature?

        if let hash = info.hash {
            signature = AptosRequest.Signature(
                type: Constants.signatureType,
                publicKey: info.publicKey,
                signature: hash
            )
        }

        return .init(
            sequenceNumber: String(info.sequenceNumber),
            sender: info.sourceAddress,
            gasUnitPrice: String(info.gasUnitPrice),
            maxGasAmount: String(info.maxGasAmount),
            expirationTimestampSecs: String(info.expirationTimestamp),
            payload: transferPayload,
            signature: signature
        )
    }
}

// MARK: - Constants

private extension AptosNetworkService {
    enum Constants {
        static let accountKeyPrefix = "0x1::account::Account"
        static let coinStoreKeyPrefix = "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>"
        static let transferPayloadType = "entry_function_payload"
        static let transferPayloadFunction = "0x1::aptos_account::transfer"
        static let aptosCoinContract = "0x1::aptos_coin::AptosCoin"
        static let aptosCoinBalanceFunction = "0x1::coin::balance"
        static let signatureType = "ed25519_signature"
        static let successTransactionSafeFactor: Decimal = 1.5
    }
}
