//
//  ALPH+FixedSizeSerde.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    protocol FixedSizeSerde: Serde {
        var serdeSize: Int { get }
    }
}

extension ALPH.FixedSizeSerde {
    var serdeSize: Int { 1 }

    func deserialize0(input: Data, f: (Data) -> Value) -> Result<Value, Error> {
        if input.count == serdeSize {
            return .success(f(input))
        } else if input.count > serdeSize {
            return .failure(ALPH.SerdeError.redundant(expected: serdeSize, got: input.count))
        } else {
            return .failure(ALPH.SerdeError.incompleteData(expected: serdeSize, got: input.count))
        }
    }

    func deserialize1(input: Data, f: (Data) -> Result<Value, ALPH.SerdeError>) -> Result<Value, ALPH.SerdeError> {
        if input.count == serdeSize {
            return f(input)
        } else if input.count > serdeSize {
            return .failure(ALPH.SerdeError.redundant(expected: serdeSize, got: input.count))
        } else {
            return .failure(ALPH.SerdeError.incompleteData(expected: serdeSize, got: input.count))
        }
    }

    func _deserialize(_ input: Data) -> Result<ALPH.Staging<Value>, Error> {
        if input.count >= serdeSize {
            let initData = input.prefix(serdeSize)
            let restData = input.dropFirst(serdeSize)
            return deserialize(initData).map { ALPH.Staging(value: $0, rest: restData) }
        } else {
            return .failure(ALPH.SerdeError.incompleteData(expected: serdeSize, got: input.count))
        }
    }
}
