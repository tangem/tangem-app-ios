//
//  WCEthTypedDataValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import struct BlockchainSdk.EIP712TypedData
import struct BlockchainSdk.EthereumAddress
import enum BlockchainSdk.JSON

struct WCEthTypedDataValidator {
    func validate(_ typedData: EIP712TypedData, signerAddress: String) throws(ValidationError) {
        let primaryType = typedData.primaryType.trimmed()

        guard !GaslessTypedDataSchema.primaryTypes.contains(where: { $0.caseInsensitiveEquals(to: primaryType) }) else {
            throw .gaslessPrimaryType
        }

        let domain: [String: JSON]

        switch typedData.domain {
        case .null:
            return
        case .object(let object):
            domain = object
        case .string, .number, .array, .bool:
            throw .malformedPayload
        }

        if let name = domain[Constants.nameKey]?.stringValue, GaslessTypedDataSchema.domainName.caseInsensitiveEquals(to: name.trimmed()) {
            throw .gaslessExecutorDomain
        }

        switch domain[Constants.verifyingContractKey] {
        case nil, .null?:
            return
        case .string(let verifyingContract)?:
            if isSameAddress(verifyingContract, signerAddress) {
                throw .signerIsVerifyingContract
            }
        case .number?, .object?, .array?, .bool?:
            throw .malformedPayload
        }
    }
}

// MARK: - Auxiliary types

extension WCEthTypedDataValidator {
    enum ValidationError: Error, Equatable {
        case malformedPayload
        case gaslessPrimaryType
        case gaslessExecutorDomain
        case signerIsVerifyingContract
    }
}

// MARK: - Private

private extension WCEthTypedDataValidator {
    enum Constants {
        static let nameKey = "name"
        static let verifyingContractKey = "verifyingContract"
    }

    func isSameAddress(_ verifyingContract: String, _ signerAddress: String) -> Bool {
        let verifyingContract = verifyingContract.trimmed()
        let signerAddress = signerAddress.trimmed()

        if verifyingContract.caseInsensitiveEquals(to: signerAddress) {
            return true
        }

        guard
            let verifyingContractAddress = EthereumAddress(string: verifyingContract),
            let signer = EthereumAddress(string: signerAddress)
        else {
            return false
        }

        return verifyingContractAddress == signer
    }
}
