//
//  StubNonceDecryptor.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
@testable import TangemBackendAuthentication

struct StubNonceDecryptor: NonceDecryptor {
    var result = Result<Data, NonceDecryptorError>.success(Data("decrypted-nonce".utf8))

    func decrypt(cipheredNonce: String) throws(NonceDecryptorError) -> Data {
        switch result {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
}
