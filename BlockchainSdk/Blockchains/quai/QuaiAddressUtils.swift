//
//  QuaiAddressUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Quai Address Derivation

// class QuaiAddressDerivation {
//
//    // Coin type для Quai
//    private static let QUAI_COIN_TYPE: UInt32 = 994
//
//    // Hardened offset для BIP44
//    private static let HARDENED_OFFSET: UInt32 = 0x80000000
//
//    // Максимальное количество попыток деривации
//    private static let MAX_DERIVATION_ATTEMPTS = 10_000_000
//
//    /// Деривирует следующий валидный адрес для указанной зоны
//    /// - Parameters:
//    ///   - rootNode: Корневой HD узел кошелька
//    ///   - account: Номер аккаунта
//    ///   - addressIndex: Начальный индекс адреса
//    ///   - zone: Целевая зона
//    ///   - isChange: Является ли это change адресом
//    /// - Returns: HD узел с валидным адресом для зоны
//    static func deriveNextAddressNode(
//        rootNode: HDNode,
//        account: Int,
//        addressIndex: Int,
//        zone: QuaiZoneType,
//        isChange: Bool = false
//    ) throws -> HDNode {
//
//        // 1. Получаем change узел: m/44'/994'/account'/change
//        let changeNode = try getChangeNode(
//            rootNode: rootNode,
//            account: account,
//            isChange: isChange
//        )
//
//        // 2. Ищем валидный адрес для зоны
//        var currentIndex = addressIndex
//
//        for attempt in 0..<MAX_DERIVATION_ATTEMPTS {
//            // Деривируем дочерний узел: m/44'/994'/account'/change/index
//            let addressNode = try changeNode.deriveChild(index: currentIndex)
//
//            // Проверяем, подходит ли адрес для указанной зоны
//            if isValidAddressForZone(address: addressNode.address, zone: zone) {
//                return addressNode
//            }
//
//            currentIndex += 1
//        }
//
//        throw QuaiError.derivationFailed(
//            "Не удалось найти валидный адрес для зоны \(zone) после \(MAX_DERIVATION_ATTEMPTS) попыток"
//        )
//    }
//
//    /// Получает change узел для аккаунта
//    private static func getChangeNode(
//        rootNode: HDNode,
//        account: Int,
//        isChange: Bool
//    ) throws -> HDNode {
//        // m/44'/994'/account'
//        let accountNode = try rootNode
//            .deriveChild(index: 44 + HARDENED_OFFSET)      // 44'
//            .deriveChild(index: QUAI_COIN_TYPE + HARDENED_OFFSET) // 994'
//            .deriveChild(index: UInt32(account) + HARDENED_OFFSET) // account'
//
//        // m/44'/994'/account'/change
//        let changeIndex = isChange ? 1 : 0
//        return try accountNode.deriveChild(index: changeIndex)
//    }
//
//    /// Проверяет, подходит ли адрес для указанной зоны
//    private static func isValidAddressForZone(address: String, zone: Zone) -> Bool {
//        // Здесь должна быть логика проверки зоны адреса
//        // В Quai адреса содержат информацию о зоне в определенных битах
//        return checkAddressZone(address: address, expectedZone: zone)
//    }
//
//    /// Проверяет зону адреса (упрощенная версия)
//    private static func checkAddressZone(address: String, expectedZone: QuaiZoneType) -> Bool {
//        // Это упрощенная версия - в реальности нужно анализировать
//        // биты адреса для определения зоны
//        // В Quai зона определяется по определенным битам в адресе
//
//        // Пример логики (нужно адаптировать под реальную спецификацию Quai):
//        let addressBytes = Data(hex: address)
//        let zoneBits = addressBytes[0] & 0x3F // Берем младшие 6 бит
//
//        switch expectedZone {
//        case .cyprus1: return zoneBits == 0x00
//        case .cyprus2: return zoneBits == 0x01
//        case .cyprus3: return zoneBits == 0x02
//        case .paxos1: return zoneBits == 0x10
//        case .paxos2: return zoneBits == 0x11
//        case .paxos3: return zoneBits == 0x12
//        case .hydra1: return zoneBits == 0x20
//        case .hydra2: return zoneBits == 0x21
//        case .hydra3: return zoneBits == 0x22
//        }
//    }
// }
//
//// MARK: - Error Types
// enum QuaiError: Error {
//    case derivationFailed(String)
//    case invalidZone(String)
//    case invalidAccount(Int)
//
//    var localizedDescription: String {
//        switch self {
//        case .derivationFailed(let reason):
//            return "Ошибка деривации: \(reason)"
//        case .invalidZone(let zone):
//            return "Неверная зона: \(zone)"
//        case .invalidAccount(let account):
//            return "Неверный аккаунт: \(account)"
//        }
//    }
// }
