//
//  SignerEffectResponse.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an account signer (create,update,remove) effect response. Superclass for signer created, signer updated and signer removed effects.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/effect.html "Effect")
///  See [Stellar guides](https://www.stellar.org/developers/guides/concepts/accounts.html#signers "Account Signer")
public class SignerEffectResponse: EffectResponse {
    
    /// Public key of the signer.
    public var publicKey:String
    
    /// Weight of the signers public key.
    public var weight:Int

    // The signer key.
    public var key: String?

    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case weight
        case key
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        publicKey = try values.decode(String.self, forKey: .publicKey)
        weight = try values.decode(Int.self, forKey: .weight)
        key = try values.decodeIfPresent(String.self, forKey: .key)

        try super.init(from: decoder)
    }
}
