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

            enum Status: String, Decodable {
                case hit
                case miss
            }

            private enum CodingKeys: CodingKey {
                case status
                case url
                case isMalicious
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
            }
        }
    }
}
