//
//  QuaiZoneUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/**
 * A zone is the lowest level shard within the Quai network hierarchy. Zones are the only shards in the network that
 * accept user transactions. The value is a hexadecimal string representing the encoded value of the zone. Read more
 * [here](https://github.com/quai-network/qips/blob/master/qip-0002.md).
 *
 * @category Constants
 */
enum QuaiZoneType: String, CaseIterable {
    case cyprus1 = "0x00"
    case cyprus2 = "0x01"
    case cyprus3 = "0x02"
    case paxos1 = "0x10"
    case paxos2 = "0x11"
    case paxos3 = "0x12"
    case hydra1 = "0x20"
    case hydra2 = "0x21"
    case hydra3 = "0x22"
}

enum QuaiLedger: Int, CaseIterable {
    case quai = 0
    case qi = 1
}

struct QuaiZoneData {
    public let name: String
    public let nickname: String
    public let shard: String
    public let context: Int
    public let byte: String

    public init(name: String, nickname: String, shard: String, context: Int, byte: String) {
        self.name = name
        self.nickname = nickname
        self.shard = shard
        self.context = context
        self.byte = byte
    }
}

enum QuaiZone {
    static let zoneData: [QuaiZoneData] = [
        QuaiZoneData(
            name: "Cyprus One",
            nickname: "cyprus1",
            shard: "zone-0-0",
            context: 2,
            byte: "0x00" // 0000 0000 region-0 zone-0
        ),
        QuaiZoneData(
            name: "Cyprus Two",
            nickname: "cyprus2",
            shard: "zone-0-1",
            context: 2,
            byte: "0x01" // 0000 0001 region-0 zone-1
        ),
        QuaiZoneData(
            name: "Cyprus Three",
            nickname: "cyprus3",
            shard: "zone-0-2",
            context: 2,
            byte: "0x02" // 0000 0010 region-0 zone-2
        ),
        QuaiZoneData(
            name: "Paxos One",
            nickname: "paxos1",
            shard: "zone-1-0",
            context: 2,
            byte: "0x10" // 0001 0000 region-1 zone-0
        ),
        QuaiZoneData(
            name: "Paxos Two",
            nickname: "paxos2",
            shard: "zone-1-1",
            context: 2,
            byte: "0x11" // 0001 0001 region-1 zone-1
        ),
        QuaiZoneData(
            name: "Paxos Three",
            nickname: "paxos3",
            shard: "zone-1-2",
            context: 2,
            byte: "0x12" // 0001 0010 region-1 zone-2
        ),
        QuaiZoneData(
            name: "Hydra One",
            nickname: "hydra1",
            shard: "zone-2-0",
            context: 2,
            byte: "0x20" // 0010 0000 region-2 zone-0
        ),
        QuaiZoneData(
            name: "Hydra Two",
            nickname: "hydra2",
            shard: "zone-2-1",
            context: 2,
            byte: "0x21" // 0010 0001 region-2 zone-1
        ),
        QuaiZoneData(
            name: "Hydra Three",
            nickname: "hydra3",
            shard: "zone-2-2",
            context: 2,
            byte: "0x22" // 0010 0010 region-2 zone-2
        ),
    ]

    private static func zoneFromBytes(_ zone: String) throws -> QuaiZoneType {
        guard let zoneEnum = QuaiZoneType(rawValue: zone) else {
            throw QuaiZoneError.invalidZone(zone)
        }
        return zoneEnum
    }

    static func toZone(_ shard: String) throws -> QuaiZoneType {
        guard let zoneData = zoneData.first(where: {
            $0.name == shard ||
                $0.byte == shard ||
                $0.nickname == shard ||
                $0.shard == shard
        }) else {
            throw QuaiZoneError.zoneNotFound(shard)
        }

        return try zoneFromBytes(zoneData.byte)
    }

    static func fromZone(_ zone: QuaiZoneType, key: ZoneDataKey) -> String {
        guard let zoneData = zoneData.first(where: { $0.byte == zone.rawValue }) else {
            return ""
        }

        switch key {
        case .name:
            return zoneData.name
        case .nickname:
            return zoneData.nickname
        case .shard:
            return zoneData.shard
        case .byte:
            return zoneData.byte
        }
    }
}

public enum ZoneDataKey {
    case name
    case nickname
    case shard
    case byte
}

public enum QuaiZoneError: Error, LocalizedError {
    case invalidZone(String)
    case zoneNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .invalidZone(let zone):
            return "Invalid zone: \(zone)"
        case .zoneNotFound(let shard):
            return "Zone not found for shard: \(shard)"
        }
    }
}
