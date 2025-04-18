//
//  SiteScan.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension BlockaidDTO {
    enum SiteScan {
        struct Request: Encodable {
            let url: String
        }

        struct Response: Decodable {
            let status: Status
            let url: String
            let isMalicious: Bool
            let attackTypes: [AttackType: Attack]

            enum Status: String, Decodable {
                case hit
                case miss
            }

            struct Attack: Decodable {
                let score: Int
                let threshold: Int
            }

            enum AttackType: String, Decodable {
                case signatureFarming = "signature_farming"
                case approvalFarming = "approval_farming"
                case setApprovalForAll = "set_approval_for_all"
                case transferFarming = "transfer_farming"
                case rawEtherTransfer = "raw_ether_transfer"
                case seaportFarming = "seaport_farming"
                case blurFarming = "blur_farming"
                case permitFarming = "permit_farming"
                case other
            }

            private enum CodingKeys: CodingKey {
                case status
                case url
                case isMalicious
                case attackTypes
            }

            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: BlockaidDTO.SiteScan.Response.CodingKeys.self)

                status = try container.decode(
                    BlockaidDTO.SiteScan.Response.Status.self,
                    forKey: BlockaidDTO.SiteScan.Response.CodingKeys.status
                )
                url = try container.decode(String.self, forKey: BlockaidDTO.SiteScan.Response.CodingKeys.url)
                isMalicious = try container.decode(
                    Bool.self,
                    forKey: BlockaidDTO.SiteScan.Response.CodingKeys.isMalicious
                )
                let attackTypesRaw = try container.decode(
                    [String: BlockaidDTO.SiteScan.Response.Attack].self,
                    forKey: BlockaidDTO.SiteScan.Response.CodingKeys.attackTypes
                )
                attackTypes = Dictionary(
                    uniqueKeysWithValues: attackTypesRaw.compactMap { key, value in
                        AttackType(rawValue: key).map { ($0, value) }
                    }
                )
            }
        }
    }
}
