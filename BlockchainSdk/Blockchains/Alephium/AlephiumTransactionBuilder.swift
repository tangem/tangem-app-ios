//
//  AlephiumTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BigInt

final class AlephiumTransactionBuilder {
    // MARK: - Private Properties

    private let isTestnet: Bool
    private let decimalValue: Decimal

    private(set) var walletPublicKey: Data

    private(set) var unspents: [ALPH.AssetOutputInfo] = []

    // MARK: - Init

    init(isTestnet: Bool, walletPublicKey: Data, decimalValue: Decimal) {
        self.isTestnet = isTestnet
        self.walletPublicKey = walletPublicKey
        self.decimalValue = decimalValue
    }

    // MARK: - Public Implementation

    func update(utxo: [AlephiumUTXO]) {
        unspents = utxo.compactMap { makeUnspent(for: $0) }
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        let unsignedTransaction = try innerBuildToSign(
            destinationAddress: transaction.destinationAddress,
            amount: transaction.amount,
            fee: transaction.fee
        )

        let hash = unsignedTransaction.transactionId.value.bytes

        return hash
    }

    func buildForSend(transaction: Transaction) throws -> Data {
        let unsignedTransaction = try innerBuildToSign(
            destinationAddress: transaction.destinationAddress,
            amount: transaction.amount,
            fee: transaction.fee
        )

        let hashForSend = ALPH.UnsignedTransactionSerde().serialize(unsignedTransaction)

        return hashForSend
    }

    // MARK: - Private Implementation

    private func makeUnspent(for utxo: AlephiumUTXO) -> ALPH.AssetOutputInfo? {
        guard let unsafeAmount = BigUInt(decimal: utxo.value) else {
            return nil
        }

        let ref = ALPH.AssetOutputRef(
            hint: ALPH.Hint(value: utxo.hint),
            key: ALPH.TxOutputRefKey(value: ALPH.Blake2b(bytes: Data(hexString: utxo.key)))
        )

        let lockupScript = ALPH.Lockup.P2PKH(pkHash: ALPH.Blake2b(bytes: walletPublicKey))

        let output = ALPH.AssetOutput(
            amount: ALPH.U256.unsafe(unsafeAmount),
            lockupScript: lockupScript,
            lockTime: ALPH.TimeStamp(utxo.lockTime),
            tokens: .init(),
            additionalData: Data(hexString: utxo.additionalData)
        )

        let assetOutputInfo = ALPH.AssetOutputInfo(
            ref: ref,
            output: output,
            outputType: ALPH.UnpersistedBlockOutput()
        )

        return assetOutputInfo
    }

    private func innerBuildToSign(
        destinationAddress: String,
        amount: Amount,
        fee: Fee
    ) throws -> ALPH.UnsignedTransaction {
        guard
            let innerAmountValue = BigUInt(decimal: amount.value * decimalValue),
            let feeParameters = fee.parameters as? AlephiumFeeParameters,
            let gasPriceValue = BigUInt(feeParameters.gasPrice.stringValue)
        else {
            throw WalletError.failedToBuildTx
        }

        let fromLockupScript = ALPH.Lockup.P2PKH(pkHash: ALPH.Blake2b.hash(walletPublicKey))
        let fromUnlockScript = ALPH.Unlock.P2PKH(publicKeyData: walletPublicKey)

        let base58DecodedData = destinationAddress.base58DecodedData
        let withoutBase58DecodedData = base58DecodedData.dropFirst()

        let outputLockupScript = ALPH.Lockup.P2PKH(pkHash: ALPH.Blake2b(bytes: withoutBase58DecodedData))

        let txOutputInfo = ALPH.TxOutputInfo(
            lockupScript: outputLockupScript,
            attoAlphAmount: ALPH.U256.unsafe(innerAmountValue),
            tokens: .init(),
            lockTime: nil,
            additionalData: nil
        )

        let gasPrice = ALPH.GasPrice(value: ALPH.U256.unsafe(gasPriceValue))
        let gasAmount = ALPH.GasBox(value: feeParameters.gasAmount)

        let networkId: ALPH.NetworkId = isTestnet ? .testnet : .mainnet

        let unsignedTransaction = try ALPH.TxUtils(dustUtxoAmount: ALPH.Constants.dustUtxoAmount)
            .transfer(
                fromLockupScript: fromLockupScript,
                fromUnlockScript: fromUnlockScript,
                outputData: txOutputInfo,
                gasOpt: gasAmount,
                gasPrice: gasPrice,
                utxos: unspents,
                networkId: networkId
            )

        return unsignedTransaction
    }
}
