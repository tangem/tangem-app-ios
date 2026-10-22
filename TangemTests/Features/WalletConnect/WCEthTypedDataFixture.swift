//
//  WCEthTypedDataFixture.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum WCEthTypedDataFixture {
    static let blockchain = Blockchain.ethereum(testnet: false)
    static let signer = "0x54f6ab13abA6c169A3E6294B7e9Ac6A02F470aab"
    static let usdcContract = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
    static let spender = "0x1111111111111111111111111111111111111111"
    static let zeroAddress = "0x0000000000000000000000000000000000000000"

    static let reportedBatchPayload = """
    {"types":{"EIP712Domain":[{"name":"name","type":"string"},{"name":"version","type":"string"},{"name":"chainId","type":"uint256"},{"name":"verifyingContract","type":"address"}],"Transaction":[{"name":"to","type":"address"},{"name":"value","type":"uint256"},{"name":"gasLimit","type":"uint256"},{"name":"data","type":"bytes"}],"Fee":[{"name":"feeToken","type":"address"},{"name":"maxTokenFee","type":"uint256"},{"name":"coinPriceInToken","type":"uint256"},{"name":"feeTransferGasLimit","type":"uint256"},{"name":"baseGas","type":"uint256"},{"name":"feeReceiver","type":"address"}],"GaslessBatchTransaction":[{"name":"transactions","type":"Transaction[]"},{"name":"fee","type":"Fee"},{"name":"nonce","type":"uint256"}]},"primaryType":"GaslessBatchTransaction","domain":{"name":"Tangem7702GaslessExecutor","version":"1","chainId":1,"verifyingContract":"0x54f6ab13abA6c169A3E6294B7e9Ac6A02F470aab"},"message":{"transactions":[{"to":"0x1111111111111111111111111111111111111111","value":"0","gasLimit":"50000","data":"0x"},{"to":"0x3333333333333333333333333333333333333333","value":"0","gasLimit":"50000","data":"0x"}],"fee":{"feeToken":"0x0000000000000000000000000000000000000000","maxTokenFee":"0","coinPriceInToken":"0","feeTransferGasLimit":"0","baseGas":"0","feeReceiver":"0x0000000000000000000000000000000000000000"},"nonce":"1"}}
    """

    static func permitPayload(primaryType: String = "Permit", domain: String = permitDomain()) -> String {
        """
        {"types":{"EIP712Domain":[{"name":"name","type":"string"},{"name":"version","type":"string"},{"name":"chainId","type":"uint256"},{"name":"verifyingContract","type":"address"}],"Permit":[{"name":"owner","type":"address"},{"name":"spender","type":"address"},{"name":"value","type":"uint256"},{"name":"nonce","type":"uint256"},{"name":"deadline","type":"uint256"}]},"primaryType":"\(primaryType)","domain":\(domain),"message":{"owner":"\(signer)","spender":"\(spender)","value":"1000000","nonce":"0","deadline":"1800000000"}}
        """
    }

    static func permitDomain(name: String = "USD Coin", verifyingContract: String = usdcContract) -> String {
        """
        {"name":"\(name)","version":"2","chainId":1,"verifyingContract":"\(verifyingContract)"}
        """
    }

    static func decode(_ json: String) throws -> EIP712TypedData {
        try JSONDecoder().decode(EIP712TypedData.self, from: Data(json.utf8))
    }
}
