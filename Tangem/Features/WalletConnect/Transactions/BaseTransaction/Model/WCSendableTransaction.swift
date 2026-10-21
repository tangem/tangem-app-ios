import Foundation
import BlockchainSdk
import TangemFoundation

struct WCSendableTransaction {
    let from: String
    let to: String
    let value: String?
    let data: String?
    let gas: String?
    let gasPrice: String?
    let maxFeePerGas: String?
    let maxPriorityFeePerGas: String?
    let nonce: String?
}

extension WCSendableTransaction {
    init(from wcTransaction: WalletConnectEthTransaction) {
        from = wcTransaction.from
        to = wcTransaction.to
        value = wcTransaction.value
        data = wcTransaction.data
        gas = wcTransaction.gas
        gasPrice = wcTransaction.gasPrice
        maxFeePerGas = nil
        maxPriorityFeePerGas = nil
        nonce = wcTransaction.nonce
    }

    func toWalletConnectTransaction() -> WalletConnectEthTransaction {
        let finalGasPrice: String?
        if let maxFeePerGas = maxFeePerGas {
            finalGasPrice = maxFeePerGas
        } else {
            finalGasPrice = gasPrice
        }

        return WalletConnectEthTransaction(
            from: from,
            to: to,
            value: value,
            data: data,
            gas: gas,
            gasPrice: finalGasPrice,
            nonce: nonce,
            chainId: nil
        )
    }

    func withUpdatedData(_ newData: String) -> WCSendableTransaction {
        return WCSendableTransaction(
            from: from,
            to: to,
            value: value,
            data: newData,
            gas: gas,
            gasPrice: gasPrice,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            nonce: nonce
        )
    }
}

// MARK: - Logging

extension WCSendableTransaction {
    func logDescription(method: WalletConnectMethod, blockchain: Blockchain) -> String {
        let chainId = blockchain.chainId.map(String.init) ?? "none"
        let dataSize = (data?.removeHexPrefix().count ?? 0) / 2

        return """
        Building \(method.rawValue) on \(blockchain.displayName) (chain ID \(chainId)): \
        from \(from), to \(to), value \(value ?? "none"), nonce \(nonce ?? "none"), gas \(gas ?? "none"), \
        gasPrice \(gasPrice ?? "none"), maxFeePerGas \(maxFeePerGas ?? "none"), \
        maxPriorityFeePerGas \(maxPriorityFeePerGas ?? "none"), data \(dataSize) bytes
        """
    }
}
