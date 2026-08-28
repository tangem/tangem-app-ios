//
//  KeychainSessionTokensRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import Foundation
private import struct TangemFoundation.UserWalletId

struct KeychainSessionTokensRepository: SessionTokensRepository {
    private let keychainRepository: any KeychainRepository

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(keychainRepository: some KeychainRepository) {
        self.keychainRepository = keychainRepository
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func persist(_ tokens: SessionTokens) async throws(SessionTokensRepositoryError) {
        let data = try encode(tokens)

        do {
            try await keychainRepository.updateOrInsert(data)
        } catch {
            throw SessionTokensRepositoryError.keychainFailure(error)
        }
    }

    func retrieve() async throws(SessionTokensRepositoryError) -> SessionTokens? {
        let encodedTokensData: Data?

        do {
            encodedTokensData = try await keychainRepository.retrieve()
        } catch {
            throw SessionTokensRepositoryError.keychainFailure(error)
        }

        guard let encodedTokensData else { return nil }

        return try decode(encodedTokensData)
    }

    func delete() async throws(SessionTokensRepositoryError) {
        do {
            try await keychainRepository.delete()
        } catch {
            throw SessionTokensRepositoryError.keychainFailure(error)
        }
    }
}

// MARK: - Codable and DTOs

extension KeychainSessionTokensRepository {
    private func encode(_ tokens: SessionTokens) throws(SessionTokensRepositoryError) -> Data {
        do {
            let versionedDTO = VersionedDTO(version: SessionTokensSchemaV1.version, dto: SessionTokensDTO(fromDomain: tokens))
            return try encoder.encode(versionedDTO)
        } catch {
            throw SessionTokensRepositoryError.encodingFailed
        }
    }

    private func decode(_ data: Data) throws(SessionTokensRepositoryError) -> SessionTokens {
        do {
            let schemaVersion = try decoder.decode(SchemaVersion.self, from: data).version

            switch schemaVersion {
            case SessionTokensSchemaV1.version:
                return try decoder.decode(VersionedDTO<SessionTokensDTO>.self, from: data).dto.toDomain
            default:
                throw SessionTokensRepositoryError.decodingFailed
            }
        } catch let error as SessionTokensRepositoryError {
            throw error
        } catch {
            throw SessionTokensRepositoryError.decodingFailed
        }
    }
}

private struct SchemaVersion: Decodable {
    let version: Int
}

private struct VersionedDTO<DTO: Codable>: Codable {
    let version: Int
    let dto: DTO
}

private typealias SessionTokensDTO = SessionTokensSchemaV1.SessionTokensDTO
private typealias TokenDTO = SessionTokensSchemaV1.TokenDTO

private enum SessionTokensSchemaV1 {
    static let version = 1

    struct SessionTokensDTO: Codable {
        let accessToken: TokenDTO
        let refreshToken: TokenDTO?
        let userWalletIDs: [Data]

        var toDomain: SessionTokens {
            SessionTokens(
                accessToken: accessToken.toDomain,
                refreshToken: refreshToken?.toDomain,
                userWalletIDs: userWalletIDs.map(UserWalletId.init(value:))
            )
        }

        init(fromDomain domainModel: SessionTokens) {
            accessToken = TokenDTO(fromDomain: domainModel.accessToken)
            refreshToken = domainModel.refreshToken.map(TokenDTO.init)
            userWalletIDs = domainModel.userWalletIDs.map(\.value)
        }
    }

    struct TokenDTO: Codable {
        let jwt: String
        let expiresAt: Date

        var toDomain: SessionTokens.Token {
            SessionTokens.Token(jwt: jwt, expiresAt: expiresAt)
        }

        init(fromDomain domainModel: SessionTokens.Token) {
            jwt = domainModel.jwt
            expiresAt = domainModel.expiresAt
        }
    }
}
