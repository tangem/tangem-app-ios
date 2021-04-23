//
//  CardData.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Detailed information about card contents.
public struct CardData: JSONStringConvertible {
	/// Tangem internal manufacturing batch ID.
	public let batchId: String?
	/// Timestamp of manufacturing.
	public let manufactureDateTime: Date?
	/// Name of the issuer.
	public let issuerName: String?
	/// Name of the blockchain.
	public let blockchainName: String?
	/// Signature of CardId with manufacturer’s private key.
	public let manufacturerSignature: Data?
	/// Mask of products enabled on card.
	public let productMask: ProductMask?
	/// Name of the token.
	public let tokenSymbol: String?
	/// Smart contract address.
	public let tokenContractAddress: String?
	/// Number of decimals in token value.
	public let tokenDecimal: Int?
}

extension CardData {
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		batchId = try? values.decode(String.self, forKey: .batchId)
		manufactureDateTime = try? values.decode(Date.self, forKey: .manufactureDateTime)
		issuerName = try? values.decode(String.self, forKey: .issuerName)
		blockchainName = try? values.decode(String.self, forKey: .blockchainName)
		manufacturerSignature = try? values.decode(Data.self, forKey: .manufacturerSignature)
		if let productMaskDictionary = try? values.decode([String:UInt8].self, forKey: .productMask),
			let rawValue = productMaskDictionary["rawValue"]  {
			productMask = ProductMask(rawValue: rawValue)
		} else {
			productMask = try values.decode(ProductMask.self, forKey: .productMask)
		}
		tokenSymbol = try? values.decode(String.self, forKey: .tokenSymbol)
		tokenContractAddress = try? values.decode(String.self, forKey: .tokenContractAddress)
		tokenDecimal = try? values.decode(Int.self, forKey: .tokenDecimal)
	}
}
