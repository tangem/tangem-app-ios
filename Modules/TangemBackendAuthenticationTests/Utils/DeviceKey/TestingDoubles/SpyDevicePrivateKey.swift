//
//  SpyDevicePrivateKey.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
private import os.lock
@testable import TangemBackendAuthentication

final class SpyDevicePrivateKey: DevicePrivateKey {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var publicKeyResult: Result<DevicePublicKey, DevicePublicKey.RawPointFormatError> {
        get { state.withLock(\.publicKeyResult) }
        set { state.withLock { $0.publicKeyResult = newValue } }
    }

    var signResult: Result<P256.Signing.ECDSASignature, any Error> {
        get { state.withLock(\.signResult) }
        set { state.withLock { $0.signResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    var publicKey: DevicePublicKey {
        get throws(DevicePublicKey.RawPointFormatError) {
            state.withLock { $0.receivedMessages.append(.publicKey) }
            return try publicKeyResult.get()
        }
    }

    func signature(for data: Data) throws -> P256.Signing.ECDSASignature {
        state.withLock { $0.receivedMessages.append(.signature(data)) }
        return try signResult.get()
    }
}

extension DevicePrivateKey where Self == SpyDevicePrivateKey {
    static var successStub: SpyDevicePrivateKey {
        let stub = SpyDevicePrivateKey()
        stub.publicKeyResult = Result(
            catching: { () throws(DevicePublicKey.RawPointFormatError) -> DevicePublicKey in
                let key = P256.Signing.PrivateKey()
                return try DevicePublicKey(
                    derRepresentation: key.publicKey.derRepresentation,
                    rawPoint: key.publicKey.x963Representation
                )
            }
        )
        stub.signResult = Result { try P256.Signing.ECDSASignature.fake }

        return stub
    }
}

extension SpyDevicePrivateKey {
    enum Message: Equatable {
        case publicKey
        case signature(Data)
    }

    private struct State {
        var publicKeyResult: Result<DevicePublicKey, DevicePublicKey.RawPointFormatError> = Result.failure(.invalidLength(actual: 67))
        var signResult: Result<P256.Signing.ECDSASignature, any Error> = Result.failure(AnyTestError())
        var receivedMessages = [Message]()
    }
}
