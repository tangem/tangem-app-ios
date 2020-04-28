//
//  WriteUserDataCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `WriteUserDataCommand`.
public struct WriteUserDataResponse: TlvCodable {
    /// Unique Tangem card ID number
    public let cardId: String
}

/**
* This command write some of User_Data, User_ProtectedData, User_Counter and User_ProtectedCounter fields.
* User_Data and User_ProtectedData are never changed or parsed by the executable code the Tangem COS.
* The App defines purpose of use, format and it's payload. For example, this field may contain cashed information
* from blockchain to accelerate preparing new transaction.
* User_Counter and User_ProtectedCounter are counters, that initial values can be set by App and increased on every signing
* of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
* For example, this fields may contain blockchain nonce value.
*
* Writing of User_Counter and User_Data protected only by PIN1.
* User_ProtectedCounter and User_ProtectedData additionaly need PIN2 to confirmation.
*/
@available(iOS 13.0, *)
public final class WriteUserDataCommand: Command {
    public typealias CommandResponse = WriteUserDataResponse
    
    private let userData: Data?
    private let userCounter: Int?
    private let userProtectedData: Data?
    private let userProtectedCounter: Int?
    
    /// Default initializer
    /// - Parameters:
    ///   - userData: Some user data to write. Protected only by PIN1
    ///   - userCounter: Counter, that initial values can be set by App and increased on every signing
    ///    of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
    ///    For example, this fields may contain blockchain nonce value.
    ///   - userProtectedData: Some protected user data to write.  Protected  by PIN1 and PIN2
    ///   - userProtectedCounter: Same as userCounter, but for userProtectedData
    public init(userData: Data?, userCounter: Int?, userProtectedData: Data?, userProtectedCounter: Int?) {
        self.userData = userData
        self.userCounter = userCounter
        self.userProtectedData = userProtectedData
        self.userProtectedCounter = userProtectedCounter
    }
    
    /// Convenience initializer for writing userData only
    /// - Parameters:
    ///   - userData: Some user data to write
    ///   - userCounter: Counter, that initial values can be set by App and increased on every signing
    ///    of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
    ///    For example, this fields may contain blockchain nonce value.
    public convenience init(userData: Data, userCounter: Int) {
        self.init(userData: userData, userCounter: userCounter, userProtectedData: nil, userProtectedCounter: nil)
    }
    
    /// Convenience initializer for writing userProtectedData only
    /// - Parameters:
    ///   - userProtectedData: Some protected user data to write.  Protected  by PIN1 and PIN2
    ///   - userProtectedCounter: Same as userCounter, but for userProtectedData
    public convenience init(userProtectedData: Data, userProtectedCounter: Int) {
        self.init(userData: nil, userCounter: nil, userProtectedData: userProtectedData, userProtectedCounter: userProtectedCounter)
    }
    
    public func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: environment.pin1)
        
        if let userData = userData, let userCounter = userCounter {
            try tlvBuilder.append(.userData, value: userData)
                .append(.userCounter, value: userCounter)
        }
        
        if let userProtectedData = userProtectedData, let userProtectedCounter = userProtectedCounter {
            try tlvBuilder.append(.userProtectedData, value: userProtectedData)
                .append(.userProtectedCounter, value: userProtectedCounter)
                .append(.pin2, value: environment.pin2)
        }
        
        return CommandApdu(.writeUserData, tlv: tlvBuilder.serialize())
    }
    
    public func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> WriteUserDataResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw SessionError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return WriteUserDataResponse(cardId: try decoder.decode(.cardId))
    }
}
