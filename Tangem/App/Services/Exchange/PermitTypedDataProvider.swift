//
//  PermitTypedDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExchange

struct PermitTypedDataProvider {
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

extension PermitTypedDataProvider: PermitTypedDataProviding {
    func buildPermitCallData(for currency: Currency, parameters: PermitParameters) async throws -> String {
        let domain = try mapToDomain(currency: currency)
        let nonce = 0 // ethereumTransactionProcessor.initialNonce
        let message = mapToPermitMessage(currency: currency, nonce: nonce, parameters: parameters)

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

        let hexString = "0x" + alignedStrings.joined().lowercased()
//        print("alignedStrings", alignedStrings)
//        print("hexString", hexString)
        print("hexString readable\n\((["0x"] + alignedStrings).joined(separator: "\n").lowercased())")
        return hexString
    }
}

private extension PermitTypedDataProvider {
    func mapToDomain(currency: Currency) throws -> EIP712Domain {
        guard let contractAddress = currency.contractAddress else {
            throw CommonError.noData
        }

        return EIP712Domain(
            name: "1INCH Token",
            version: "1",
            chainId: currency.blockchain.chainId,
            verifyingContract: contractAddress
        )
    }

    func mapToPermitMessage(currency: Currency, nonce: Int, parameters: PermitParameters) -> EIP2612PermitMessage {
        EIP2612PermitMessage(
            owner: parameters.walletAddress,
            spender: parameters.spenderAddress,
            value: String(describing: parameters.amount),
            nonce: nonce,
            deadline: 1672559603
        )
    }
}
