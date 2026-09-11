//
//  EthereumEIP1559FeeParametersMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BigInt

enum EthereumEIP1559FeeParametersMapper {
    static func map(
        response: EthereumEIP1559FeeResponse,
        blockchain: Blockchain
    ) -> [EthereumEIP1559FeeParameters] {
        [
            map(fee: response.fees.low, gasLimit: response.gasLimit, blockchain: blockchain),
            map(fee: response.fees.market, gasLimit: response.gasLimit, blockchain: blockchain),
            map(fee: response.fees.fast, gasLimit: response.gasLimit, blockchain: blockchain),
        ]
    }
}

private extension EthereumEIP1559FeeParametersMapper {
    static func map(
        fee: EthereumEIP1559FeeResponse.ETHFee,
        gasLimit: BigUInt,
        blockchain: Blockchain
    ) -> EthereumEIP1559FeeParameters {
        EthereumEIP1559FeeParameters(
            gasLimit: gasLimit,
            maxFeePerGas: fee.max,
            priorityFee: fee.priority
        )
        .applyingFeeRules(for: blockchain)
    }
}
