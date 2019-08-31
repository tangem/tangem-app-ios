//  web3swift
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import Foundation
import BigInt
import PromiseKit

extension web3.Eth {
    
    public func estimateGasPromise(_ transaction: EthereumTransaction, transactionOptions: TransactionOptions?) -> Promise<BigUInt>{
        let queue = web3.requestDispatcher.queue
        do {
            guard let request = EthereumTransaction.createRequest(method: .estimateGas, transaction: transaction, transactionOptions: transactionOptions) else {
                throw Web3Error.processingError(desc: "Transaction is invalid")
            }
            let rp = web3.dispatch(request)
            return rp.map(on: queue ) { response in
                guard let value: BigUInt = response.getValue() else {
                    if response.error != nil {
                        throw Web3Error.nodeError(desc: response.error!.message)
                    }
                    throw Web3Error.nodeError(desc: "Invalid value from Ethereum node")
                }
                return value
            }
        } catch {
            let returnPromise = Promise<BigUInt>.pending()
            queue.async {
                returnPromise.resolver.reject(error)
            }
            return returnPromise.promise
        }
    }
}

