import Foundation

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
