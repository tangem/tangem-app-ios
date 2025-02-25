//
//  VisaAddressParser.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct AddressParser {
    private let addressLength = 42
    private let paddedAddressDataChunkLength = 64
    private let prefixLength = "0x".count

    private var addressService: AddressService

    init(isTestnet: Bool) {
        let blockchain = VisaUtilities(isTestnet: isTestnet).visaBlockchain
        addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
    }

    func parseAddressResponse(_ response: String) throws (VisaParserError) -> String {
        guard
            response.hasHexPrefix(),
            response.count >= addressLength
        else {
            throw .addressResponseDoesntContainAddress
        }

        var parsedAddress = response
        if parsedAddress.count > addressLength {
            parsedAddress = String(parsedAddress.suffix(addressLength - prefixLength)).addHexPrefix()
        }

        guard addressService.validate(parsedAddress) else {
            throw .noValidAddress
        }

        return parsedAddress
    }

    func parseAddressesResponse(_ response: String) throws (VisaParserError) -> [String] {
        guard response.count >= addressLength else {
            throw .addressResponseDoesntContainAddress
        }

        let clearedResponse = response.removeHexPrefix()

        guard clearedResponse.count % paddedAddressDataChunkLength == 0 else {
            throw .addressesResponseHasWrongLength
        }

        let addresses: [String] = stride(from: 0, to: clearedResponse.count, by: paddedAddressDataChunkLength).compactMap { index in
            let start = clearedResponse.index(clearedResponse.startIndex, offsetBy: index)
            let end = clearedResponse.index(start, offsetBy: paddedAddressDataChunkLength)
            let chunk = String(clearedResponse[start ..< end])
            guard chunk.count > addressLength else {
                return nil
            }

            let parsedAddress = String(chunk.stripLeadingZeroes()).addHexPrefix()

            guard addressService.validate(parsedAddress) else {
                return nil
            }

            return parsedAddress
        }

        return addresses
    }
}
