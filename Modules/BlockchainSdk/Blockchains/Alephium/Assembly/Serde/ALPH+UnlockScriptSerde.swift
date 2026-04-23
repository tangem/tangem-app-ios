//
//  ALPH+UnlockScriptSerde.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    struct UnlockScriptSerde: Serde {
        typealias T = UnlockScript

        func serialize(_ input: UnlockScript) -> Data {
            var data = Data()
            switch input {
            case let p2pkh as Unlock.P2PKH:
                data.append(0) // Prefix for P2PKH
                data.append(Unlock.P2PKH.unlockSerde.serialize(p2pkh))
            case is SameAsPrevious:
                data.append(3) // Prefix for SameAsPrevious
            default:
                assertionFailure("Unsupported UnlockScript type")
                return Data()
            }
            return data
        }

        func _deserialize(_ input: Data) -> Result<Staging<ALPH.UnlockScript>, any Error> {
            do {
                let deserialize = try ALPH.ByteSerde()._deserialize(input).get()

                switch deserialize.value {
                case 0:
                    let result = try Unlock.P2PKH.unlockSerde._deserialize(deserialize.rest).get()
                    return .success(Staging(value: result.value, rest: result.rest))
                case 3:
                    return .success(Staging(value: SameAsPrevious(), rest: deserialize.rest))
                default:
                    return .failure(SerdeError.wrongFormat(message: "Invalid unlock script prefix"))
                }
            } catch {
                return .failure(error)
            }
        }
    }
}
