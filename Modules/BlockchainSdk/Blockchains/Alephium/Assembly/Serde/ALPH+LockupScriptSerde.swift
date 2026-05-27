//
//  ALPH+LockupScript.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    struct LockupScriptSerde: Serde {
        typealias T = LockupScript

        func serialize(_ input: LockupScript) -> Data {
            var data = Data()
            switch input {
            case let p2pkh as Lockup.P2PKH:
                data.append(UInt8(0)) // Prefix for P2PKH
                data.append(Blake2b.serde.serialize(p2pkh.pkHash))
            default:
                assertionFailure("Unsupported UnlockScript type")
                return Data()
            }
            return data
        }

        func _deserialize(_ input: Data) -> Result<Staging<LockupScript>, Error> {
            do {
                let deserialize = try ALPH.ByteSerde()._deserialize(input).get()

                switch deserialize.value {
                case 0:
                    let result = try Blake2b.serde._deserialize(deserialize.rest).get()
                    return .success(Staging(value: Lockup.P2PKH(pkHash: result.value), rest: result.rest))
                default:
                    return .failure(SerdeError.wrongFormat(message: "Invalid lockupScript prefix \(deserialize.value)"))
                }
            } catch {
                return .failure(error)
            }
        }
    }
}
