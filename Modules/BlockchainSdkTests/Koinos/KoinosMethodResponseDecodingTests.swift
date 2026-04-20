//
//  KoinosMethodResponseDecodingTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

@testable import BlockchainSdk
import Testing

struct KoinosMethodResponseDecodingTests {
    private let decoder = JSONDecoder.withSnakeCaseStrategy

    @Test
    func getAccountNonceResponseDecoding1() throws {
        let jsonData = """
        {
            "nonce": "KAA="
        }
        """
        .data(using: .utf8)

        let response = try decoder.decode(KoinosMethod.GetAccountNonce.Response.self, from: #require(jsonData))
        let nonce = try KoinosDTOMapper.convertNonce(response)

        #expect(nonce.nonce == 0)
    }

    @Test
    func getAccountNonceResponseDecoding2() throws {
        let jsonData = """
        {
            "nonce": "KAE="
        }
        """
        .data(using: .utf8)

        let response = try decoder.decode(KoinosMethod.GetAccountNonce.Response.self, from: #require(jsonData))
        let nonce = try KoinosDTOMapper.convertNonce(response)

        #expect(nonce.nonce == 1)
    }

    @Test
    func nonceEncoding1() throws {
        let encodedNonce = try Koinos_Chain_value_type.with {
            $0.uint64Value = 0
        }
        .serializedData()
        .base64URLEncodedString()

        #expect(encodedNonce == "KAA=")
    }

    @Test
    func nonceEncoding2() throws {
        let encodedNonce = try Koinos_Chain_value_type.with {
            $0.uint64Value = 1
        }
        .serializedData()
        .base64URLEncodedString()

        #expect(encodedNonce == "KAE=")
    }

    @Test
    func decodeSubmitTransaction() throws {
        let jsonData = """
        {
          "jsonrpc": "2.0",
          "result": {
            "receipt": {
              "compute_bandwidth_used": "567032",
              "events": [
                {
                  "data": "ChkA8mJA6tglu_8tyGCqJg4SHWI0-5vRA7HNEhkAUy8yqjA1wCRKcu3O-rjKtpusA3tLjzCzGICt4gQ=",
                  "source": "15DJN4a8SgrbGhhGksSBASiSYjGnMU8dGL",
                  "name": "koinos.contracts.token.transfer_event",
                  "impacted": [
                    "18aqdHq6UqinPwpnw3fRGhw9DEDLd2nxGz",
                    "1P6cEChFZqiuyEMJiooRSouSavwy6hTjFA"
                  ]
                }
              ],
              "id": "0x1220dcea440a0176cdea7ec2a2985bc9c2f31f05ecc653fbd91c4357c97e008feae1",
              "max_payer_rc": "145039218",
              "state_delta_entries": [
                {
                  "object_space": {
                    "system": true,
                    "id": 4
                  },
                  "key": "APJiQOrYJbv_LchgqiYOEh1iNPub0QOxzQ==",
                  "value": "KAk="
                },
                {
                  "object_space": {
                    "system": true,
                    "id": 1,
                    "zone": "AC4z_RqpB7IkzpzmyUIokB0oOgLalW2nkQ=="
                  },
                  "key": "AFMvMqowNcAkSnLtzvq4yrabrAN7S48wsw==",
                  "value": "CMCyzTsQt7_zKRiCouiGgzI="
                },
                {
                  "object_space": {
                    "system": true,
                    "id": 1,
                    "zone": "AC4z_RqpB7IkzpzmyUIokB0oOgLalW2nkQ=="
                  },
                  "key": "APJiQOrYJbv_LchgqiYOEh1iNPub0QOxzQ==",
                  "value": "CMDVkIMBEOLj1zcYgqLohoMy"
                }
              ],
              "rc_limit": "35926586",
              "rc_used": "18257680",
              "payer": "1P6cEChFZqiuyEMJiooRSouSavwy6hTjFA",
              "network_bandwidth_used": "311"
            }
          },
          "id": 1
        }
        """
        .data(using: .utf8)

        let response = try decoder
            .decode(
                JSONRPC.Response<
                    KoinosMethod.SubmitTransaction.Response,
                    JSONRPC.APIError
                >.self,
                from: #require(jsonData)
            )

        #expect(response.id == 1)
    }

    @Test
    func decodeEmptyResult() throws {
        let jsonData = """
        {
            "jsonrpc": "2.0",
            "result": {

            },
            "id": 1
        }
        """
        .data(using: .utf8)

        let result = try decoder
            .decode(
                JSONRPC.Response<
                    KoinosMethod.ReadContract.Response,
                    JSONRPC.APIError
                >.self,
                from: #require(jsonData)
            )

        #expect(result.jsonrpc == "2.0")
        #expect(result.id == 1)

        if case .success(let value) = result.result {
            #expect(value.result == nil)
        } else {
            #expect(Bool(false), Comment(rawValue: "Expected result to be .success"))
        }
    }
}
