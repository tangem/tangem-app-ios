//
//  GaslessTransactionDataBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt

extension GaslessTransactionDataBuilder {
    enum GaslessTransactionData {
        struct GaslessTransaction {
            let transaction: Transaction
            let fee: Fee
            let nonce: String
            let signedData: SignedGaslessData
        }

        struct Transaction {
            let address: String
            let value: String
            let data: String
        }

        struct Fee {
            let feeToken: String
            let maxTokenFee: String
            let coinPriceInToken: String
            let feeTransferGasLimit: String
            let baseGas: String
        }

        struct SignedGaslessData {
            let eip712Signature: String
            let eip7702Auth: Eip7702Authorization
            
            struct Eip7702Authorization {
                let chainId: BigUInt
                let address: String
                let nonce: String
                let yParity: BigUInt
                let r: String
                let s: String
            }
        }
    }
}

enum GaslessTransactionDataBuilderError: Error {
    case failedToBuildTransactionData
    case failedToBuildMetaTransaction
    case failedToMakeGaslessTransactionFee
    case failedToSignTransactions
}

struct GaslessTransactionDataBuilder {
    let walletModel: any WalletModel
    let signer: TangemSigner
    let balanceConverter = BalanceConverter()

    func buildMetaTransaction(
        bsdkTransaction: BSDKTransaction,
        tokenFee: TokenFee
    ) async throws -> GaslessTransactionData.GaslessTransaction {
        // 1) get chainId
        guard let chainId = tokenFee.tokenItem.blockchain.chainId else {
            throw GaslessTransactionDataBuilderError.failedToBuildMetaTransaction
        }

        // 2) get transaction
        let transactionData = try makeTransaction(from: bsdkTransaction)

        // 3) get fee
        let feeData = try await makeGaslessTransactionFee(tokenFee: tokenFee)
        
        // 4) get smart contract nonce
        
        let smartContractNonce = try await getSmartContractNonce()
        
        // 4) sign
        let signedData = try await makeSignedGaslessData(
            transaction: transactionData,
            fee: feeData,
            chainId: chainId,
            smartContractNonce: smartContractNonce
        )
        
        return GaslessTransactionData.GaslessTransaction(
            transaction: transactionData,
            fee: feeData,
            nonce: smartContractNonce.description,
            signedData: signedData
        )
    }

    // MARK: - Private Implementation
    
    
    private func makeSignedGaslessData(
        transaction: GaslessTransactionData.Transaction,
        fee: GaslessTransactionData.Fee,
        chainId: Int,
        smartContractNonce: BigUInt,
    ) async throws -> GaslessTransactionData.SignedGaslessData {
        let eip7702Data = try await getEIP7702Data()

        let eip712Hash = try await makeEIP712Hash(
            transaction: transaction,
            fee: fee,
            nonce: smartContractNonce.description,
            chainId: chainId.description
        )

        let signedHashes = try await signer
            .sign(hashes: [eip7702Data.data, eip712Hash], walletPublicKey: walletModel.publicKey)
            .mapToResult()
            .async()

        guard case .success(let signatures) = signedHashes, signatures.count == 2 else {
            throw GaslessTransactionDataBuilderError.failedToSignTransactions
        }

        let eip7702Unmarshalled = try UnmarshalUtil.unmarshalSignature(
            signatureInfo: signatures[0],
            publicKey: walletModel.publicKey.blockchainKey
        )

        let eip712Unmarshalled = try UnmarshalUtil.unmarshalSignature(
            signatureInfo: signatures[1],
            publicKey: walletModel.publicKey.blockchainKey
        )

        return GaslessTransactionData.SignedGaslessData(
            eip712Signature: eip712Unmarshalled.extended.data.hexString.addHexPrefix(),
            eip7702Auth: .init(
                chainId: eip7702Data.chainId,
                address: eip7702Data.address,
                nonce: eip7702Data.nonce.description,
                yParity: eip7702Unmarshalled.yParity,
                r: eip7702Unmarshalled.r.hexString.addHexPrefix(),
                s: eip7702Unmarshalled.s.hexString.addHexPrefix()
            )
        )
    }
    
    private func makeTransaction(from bsdkTransaction: BSDKTransaction) throws -> GaslessTransactionData.Transaction {
        guard let ethParams = bsdkTransaction.params as? EthereumTransactionParams,
              let callData = ethParams.data
        else {
            throw GaslessTransactionDataBuilderError.failedToBuildTransactionData
        }
        
        return GaslessTransactionData.Transaction(
            address: bsdkTransaction.destinationAddress,
            value: "0",
            data: callData.hexString.addHexPrefix()
        )
    }

    private func makeEIP712Hash(
        transaction: GaslessTransactionData.Transaction,
        fee: GaslessTransactionData.Fee,
        nonce: String,
        chainId: String
    ) async throws -> Data {
        guard let provider = walletModel.ethereumGaslessDataProvider else {
            throw GaslessTransactionDataBuilderError.failedToBuildMetaTransaction
        }

        let verifyingContract = try provider.getGaslessExecutorContractAddress()

        let typedData = GaslessTransactionsEIP712Util().makeGaslessTypedData(
            transaction: transaction,
            fee: fee,
            nonce: nonce,
            chainId: chainId,
            verifyingContract: verifyingContract
        )

        return typedData.signHash
    }

    private func makeGaslessTransactionFee(tokenFee: TokenFee) async throws -> GaslessTransactionData.Fee {
        guard case .success(let bsdkFee) = tokenFee.value,
              let parameters = bsdkFee.parameters as? EthereumEIP1559FeeParameters,
              let tokenId = tokenFee.tokenItem.id,
              let contractAddress = tokenFee.tokenItem.contractAddress
        else {
            throw GaslessTransactionDataBuilderError.failedToBuildMetaTransaction
        }

        let feeTransferGasLimit = parameters.gasLimit
        let feeInCoin = bsdkFee.amount.value
        let coinPriceInToken = try await calculateCoinPriceInToken(tokenId: tokenId)
        let maxTokenFee = coinPriceInToken * feeInCoin

        return GaslessTransactionData.Fee(
            feeToken: contractAddress,
            maxTokenFee: maxTokenFee.stringValue,
            coinPriceInToken: coinPriceInToken.stringValue,
            feeTransferGasLimit: feeTransferGasLimit.description,
            baseGas: Constants.baseGas
        )
    }

    private func calculateCoinPriceInToken(tokenId: String) async throws -> Decimal {
        let coinId = walletModel.tokenItem.blockchain.coinId

        let coinInFiat = try await balanceConverter.convertToFiat(1, currencyId: coinId)
        let tokenInFiat = try await balanceConverter.convertToFiat(1, currencyId: tokenId)

        var coinPriceInToken = coinInFiat / tokenInFiat

        // Shift the decimal point to the right by token decimals
        coinPriceInToken *= walletModel.tokenItem.blockchain.decimalValue

        // Add 1% on top (client-side only, backend skips this step)
        coinPriceInToken *= Decimal(1.01)

        // 6. Keep only the integer part, rounding up
        let rounded = coinPriceInToken.rounded(roundingMode: .up)
        return rounded
    }

    private func getEIP7702Data() async throws -> EIP7702AuthorizationData {
        guard let provider = walletModel.ethereumGaslessDataProvider else {
            throw GaslessTransactionDataBuilderError.failedToBuildMetaTransaction
        }

        return try await provider.prepareEIP7702AuthorizationData()
    }

    private func getSmartContractNonce() async throws -> BigUInt {
        guard let networkProvider = walletModel.ethereumNetworkProvider else {
            throw GaslessTransactionDataBuilderError.failedToBuildMetaTransaction
        }

        return try await networkProvider.getSmartContractNonce()
    }
    
    private func getExecutorContractAddress() throws -> String {
        guard let provider = walletModel.ethereumGaslessDataProvider else {
            throw GaslessTransactionDataBuilderError.failedToBuildMetaTransaction
        }
        
        return try provider.getGaslessExecutorContractAddress()
    }
    
    private func getNonceLatest() async throws -> String {
        guard let networkProvider = walletModel.ethereumNetworkProvider else {
            throw GaslessTransactionDataBuilderError.failedToBuildMetaTransaction
        }

        return try await networkProvider.getTxCount(walletModel.defaultAddress.value).async().description
    }
}

// MARK: - Constants

extension GaslessTransactionDataBuilder {
    enum Constants {
        static let baseGas = "100000"
    }
}


// MARK: - Pretty print helpers for GaslessTransactionData

extension GaslessTransactionDataBuilder.GaslessTransactionData.GaslessTransaction {
    func prettyPrinted(
        userAddress: String,
        chainId: Int
    ) -> String {
        """
        {
           "gaslessTransaction": {
              "transaction": \(transaction.prettyPrinted),
              "fee": \(fee.prettyPrinted),
              "nonce": "\(nonce)"
           },
           "signature": "\(signedData.eip712Signature)",
           "userAddress": "\(userAddress)",
           "chainId": \(chainId),
           "eip7702auth": \(signedData.eip7702Auth.prettyPrinted)
        }
        """
    }
}

// MARK: Transaction

extension GaslessTransactionDataBuilder.GaslessTransactionData.Transaction {
    var prettyPrinted: String {
        """
        {
                 "to": "\(address)",
                 "value": "\(value)",
                 "data": "\(data)"
              }
        """
    }
}

// MARK: Fee

extension GaslessTransactionDataBuilder.GaslessTransactionData.Fee {
    var prettyPrinted: String {
        """
        {
                 "feeToken": "\(feeToken)",
                 "maxTokenFee": "\(maxTokenFee)",
                 "coinPriceInToken": "\(coinPriceInToken)",
                 "feeTransferGasLimit": "\(feeTransferGasLimit)",
                 "baseGas": "\(baseGas)"
              }
        """
    }
}

// MARK: EIP-7702 Authorization

extension GaslessTransactionDataBuilder.GaslessTransactionData.SignedGaslessData.Eip7702Authorization {
    var prettyPrinted: String {
        """
        {
              "chainId": \(chainId),
              "address": "\(address)",
              "nonce": "\(nonce)",
              "yParity": \(yParity),
              "r": "\(r)",
              "s": "\(s)"
           }
        """
    }
}
