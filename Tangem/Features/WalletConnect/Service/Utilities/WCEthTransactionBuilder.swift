import Foundation
import BlockchainSdk
import BigInt

protocol WCEthTransactionBuilder {
    func buildTx(
        from transaction: WCSendableTransaction,
        for walletModel: any WalletModel
    ) async throws -> Transaction
}

struct CommonWCEthTransactionBuilder {
    private let zeroString = "0x0"

    private func getGasLimit(
        for tx: WCSendableTransaction,
        with amount: Amount,
        using ethereumNetworkProvider: EthereumNetworkProvider,
        blockchain: Blockchain
    ) async throws -> BigUInt {
        if let dappGasLimit = tx.gas?.hexToInteger {
            if case .mantle = blockchain {
                return MantleUtils.multiplyGasLimit(dappGasLimit, with: MantleUtils.feeGasLimitMultiplier)
            }
            return BigUInt(dappGasLimit)
        }

        let valueString = amount.value.isZero ? zeroString : tx.value

        let gasLimitBigInt = try await ethereumNetworkProvider.getGasLimit(
            to: tx.to,
            from: tx.from,
            value: valueString,
            data: tx.data
        ).async()
        return gasLimitBigInt
    }

    private func getFee(
        for tx: WCSendableTransaction,
        with amount: Amount,
        blockchain: Blockchain,
        using ethereumNetworkProvider: EthereumNetworkProvider
    ) async throws -> Fee {
        async let gasLimit = getGasLimit(
            for: tx,
            with: amount,
            using: ethereumNetworkProvider,
            blockchain: blockchain
        )

        let feeParameters: EthereumFeeParameters

        if let maxFeePerGasString = tx.maxFeePerGas,
           let maxPriorityFeeString = tx.maxPriorityFeePerGas,
           let maxFeePerGas = BigUInt(maxFeePerGasString.removeHexPrefix(), radix: 16),
           let priorityFee = BigUInt(maxPriorityFeeString.removeHexPrefix(), radix: 16) {
            feeParameters = EthereumEIP1559FeeParameters(
                gasLimit: try await gasLimit,
                maxFeePerGas: maxFeePerGas,
                priorityFee: priorityFee
            )
        } else {
            let gasPrice = tx.gasPrice?.hexToInteger.map { BigUInt($0) }
            feeParameters = try await ethereumNetworkProvider.getFee(gasLimit: gasLimit, supportsEIP1559: blockchain.supportsEIP1559, gasPrice: gasPrice)
        }

        let feeValue = feeParameters.calculateFee(decimalValue: blockchain.decimalValue)
        let gasAmount = Amount(with: blockchain, value: feeValue)

        let fee = Fee(gasAmount, parameters: feeParameters)
        return fee
    }
}

extension CommonWCEthTransactionBuilder: WCEthTransactionBuilder {
    func buildTx(
        from wcTransaction: WCSendableTransaction,
        for walletModel: any WalletModel
    ) async throws -> Transaction {
        guard let ethereumNetworkProvider = walletModel.ethereumNetworkProvider else {
            let error = WalletConnectTransactionRequestProcessingError.missingGasLoader
            WCLogger.error(error: error)
            throw error
        }

        let blockchain = walletModel.tokenItem.blockchain
        let rawValue = wcTransaction.value ?? zeroString

        guard let value = EthereumUtils.parseEthereumDecimal(rawValue, decimalsCount: blockchain.decimalCount) else {
            let error = ETHError.failedToParseBalance(value: rawValue, address: "", decimals: blockchain.decimalCount)
            WCLogger.error(error: error)
            throw error
        }

        let valueAmount = Amount(with: blockchain, type: .coin, value: value)
        async let walletUpdate: () = walletModel.update(silent: false, features: .balances)
        let fee = try await getFee(for: wcTransaction, with: valueAmount, blockchain: blockchain, using: ethereumNetworkProvider)
        let _ = await walletUpdate

        var transaction = try await walletModel.transactionCreator.createTransaction(
            amount: valueAmount,
            fee: fee,
            sourceAddress: wcTransaction.from,
            destinationAddress: wcTransaction.to
        )

        let contractDataString = wcTransaction.data?.removeHexPrefix() ?? ""
        let wcTxData = Data(hexString: String(contractDataString))

        transaction.params = EthereumTransactionParams(
            data: wcTxData,
            nonce: wcTransaction.nonce?.hexToInteger
        )

        return transaction
    }
}
