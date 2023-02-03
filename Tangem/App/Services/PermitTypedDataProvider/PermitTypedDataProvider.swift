//
//  CommonPermitTypedDataService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExchange

struct CommonPermitTypedDataService {
    private let ethereumTransactionProcessor: EthereumTransactionProcessor
    private let signTypedDataProvider: SignTypedDataProviding
    private let decimalNumberConverter: DecimalNumberConverting

    init(
        ethereumTransactionProcessor: EthereumTransactionProcessor,
        signTypedDataProvider: SignTypedDataProviding,
        decimalNumberConverter: DecimalNumberConverting
    ) {
        self.ethereumTransactionProcessor = ethereumTransactionProcessor
        self.signTypedDataProvider = signTypedDataProvider
        self.decimalNumberConverter = decimalNumberConverter
    }
}

extension CommonPermitTypedDataService: PermitTypedDataService {
    func buildPermitCallData(for currency: Currency, parameters: PermitParameters) async throws -> String {
        assert("0x1111111254eeb25477b68fb85ed929f73a960582" == parameters.spenderAddress)

        let domain = try mapToDomain(currency: currency)
        let nonce: Int? = nil // ethereumTransactionProcessor.initialNonce
        let message = mapToPermitMessage(currency: currency, nonce: nonce, parameters: parameters)
        print("Domain \n", domain)
        print("Message \n", message)

        let signature = try await signTypedDataProvider.buildPermitSignature(domain: domain, message: message)

        let ownerAddressHex = Data(hexString: message.owner)
        let spenderAddressHex = Data(hexString: message.spender)
//        let nonceAligned = decimalNumberConverter.encoded(value: Decimal(message.nonce), decimalCount: 0)
        let valueAligned = decimalNumberConverter.encoded(value: Decimal(string: message.value)!, decimalCount: 0)
        let deadlineAligned = decimalNumberConverter.encoded(value: Decimal(message.deadline), decimalCount: 0)
//        let allowedAligned = decimalNumberConverter.encoded(value: 1, decimalCount: 0)

        let dataParametersForPermit: [Data?] = [
            ownerAddressHex,
            spenderAddressHex,
            valueAligned,
            deadlineAligned,
//            allowedAligned,
            signature.v,
            signature.r,
            signature.s,
        ]

        let alignedStrings = dataParametersForPermit.compactMap { $0?.aligned(to: 32).hexString }

//        guard alignedStrings.count >= 7 else {
//            assertionFailure("some data isn't found")
//            throw CommonError.noData
//        }

        let hexString = alignedStrings.joined().lowercased() // "0x" +
//        print("alignedStrings", alignedStrings)
//        print("hexString", hexString)
        print("hexString readable\n\(alignedStrings.joined(separator: "\n").lowercased())") // ["0x"] +
        return hexString
    }
}

private extension CommonPermitTypedDataService {
    func mapToDomain(currency: Currency) throws -> EIP712Domain {
        guard let contractAddress = currency.contractAddress else {
            throw CommonError.noData
        }

        return EIP712Domain(
            name: currency.name, //  "1INCH Token"
            version: "eth_signTypedData",
            chainId: currency.blockchain.chainId,
            verifyingContract: contractAddress
        )
    }

    func mapToPermitMessage(currency: Currency, nonce: Int?, parameters: PermitParameters) -> EIP2612PermitMessage {
        EIP2612PermitMessage(
            owner: parameters.walletAddress,
            spender: parameters.spenderAddress,
            value: String(describing: parameters.amount),
            nonce: nonce,
            deadline: 1685423273000 // Milliseconds (1/1,000 second) Tue May 30 2023 05:07:53 GMT+0000
        )
    }
}
