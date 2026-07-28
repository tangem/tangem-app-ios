//
//  TangemPayBankCredentialsResponse.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct TangemPayBankCredentialsResponse: Decodable {
    public let beneficiaryName: String
    public let beneficiaryAddress: String
    public let beneficiaryBankName: String
    public let beneficiaryBankAddress: String
    public let accountNumber: String
    public let routingNumber: String
}
