import Foundation
import CryptoKit
import TangemSdk

/// EncodingProtocol provides static methods for encrypting and decrypting data using AES-GCM and password-based key derivation.
/// It supports password-based encryption with PBKDF2 key stretching and includes encoding/decoding helpers for storing encrypted payloads.
enum AESEncoder {
    /// Encrypts the given content using a password. The password is stretched with PBKDF2 and a random salt.
    /// - Parameters:
    ///   - password: The password to use for encryption.
    ///   - content: The data to encrypt.
    /// - Returns: The encoded encrypted data, including salt and versioning.
    /// - Throws: EncodingError if encryption fails.
    static func encryptWithPassword(password: String, content: Data) throws -> Data {
        let salt = try CryptoUtils.generateRandomBytes(count: Constants.saltSize)
        let stretched = try stretch(password: password, salt: salt)
        let encrypted = try encryptAES(rawEncryptionKey: Data(stretched), rawData: content, associatedData: salt)

        return encode(salt: salt, encryptedData: encrypted)
    }

    /// Decrypts data that was encrypted with encryptWithPassword.
    /// - Parameters:
    ///   - password: The password to use for decryption.
    ///   - encryptedData: The encoded encrypted data.
    /// - Returns: The decrypted data.
    /// - Throws: EncodingError if decryption fails or the password is invalid.
    static func decryptWithPassword(password: String, encryptedData: Data) throws -> Data {
        let (salt, encrypted) = try decode(data: encryptedData)
        let stretched = try stretch(password: password, salt: salt)

        return try decryptAES(rawEncryptionKey: stretched, encryptedData: encrypted, associatedData: salt)
    }

    /// Encrypts data using AES-GCM with the provided raw encryption key.
    /// - Parameters:
    ///   - rawEncryptionKey: The AES key (must be 16, 24, or 32 bytes).
    ///   - rawData: The data to encrypt.
    ///   - associatedData: Optional additional authenticated data (AAD).
    /// - Returns: The encrypted data in the format [IV length][IV][ciphertext][tag].
    /// - Throws: EncodingError if the key length is invalid or encryption fails.
    static func encryptAES(rawEncryptionKey: Data, rawData: Data, associatedData: Data = Data()) throws -> Data {
        // Ensure the encryption key length is valid for AES (16, 24, or 32 bytes)
        guard Constants.possibleEncryptionKeyLengths.contains(rawEncryptionKey.count) else {
            throw EncodingError.invalidEncryptionKeyLength
        }

        // Generate a random IV (nonce) for AES-GCM
        let iv = try CryptoUtils.generateRandomBytes(count: Constants.ivLengthByte)

        // Create a symmetric key from the raw encryption key
        let key = SymmetricKey(data: rawEncryptionKey)
        // Create a nonce from the IV
        let nonce = try AES.GCM.Nonce(data: iv)

        // Encrypt the data using AES-GCM with the key, nonce, and associated data
        let sealedBox = try AES.GCM.seal(rawData, using: key, nonce: nonce, authenticating: associatedData)

        // Prepare the result: [IV length][IV][ciphertext][tag]
        var result = Data()
        result.append(UInt8(iv.count))
        result.append(iv)
        result.append(sealedBox.ciphertext)
        result.append(sealedBox.tag)
        return result
    }

    /// Decrypts data encrypted with encryptAES.
    /// - Parameters:
    ///   - rawEncryptionKey: The AES key (must be 16, 24, or 32 bytes).
    ///   - encryptedData: The encrypted data in the format [IV length][IV][ciphertext][tag].
    ///   - associatedData: Optional additional authenticated data (AAD).
    /// - Returns: The decrypted data.
    /// - Throws: EncodingError if the key length is invalid or decryption fails.
    static func decryptAES(rawEncryptionKey: Data, encryptedData: Data, associatedData: Data = Data()) throws -> Data {
        guard Constants.possibleEncryptionKeyLengths.contains(rawEncryptionKey.count) else {
            throw EncodingError.invalidEncryptionKeyLength
        }

        var cursor = 0

        // Read IV length
        guard encryptedData.count > 1 else {
            throw EncodingError.invalidPayload
        }
        let ivLength = Int(encryptedData[cursor])
        cursor += 1

        // Extract IV
        guard encryptedData.count >= cursor + ivLength else {
            throw EncodingError.invalidPayload
        }
        let iv = encryptedData[cursor ..< cursor + ivLength]
        cursor += ivLength

        // Remaining should be at least 16 bytes (tag)
        guard encryptedData.count >= cursor + 16 else {
            throw EncodingError.invalidPayload
        }

        // Extract ciphertext and tag
        let cipherAndTag = encryptedData[cursor...]
        let tagStart = cipherAndTag.count - 16
        let cipherText = cipherAndTag.prefix(tagStart)
        let tag = cipherAndTag.suffix(16)

        let nonce = try AES.GCM.Nonce(data: iv)
        let key = SymmetricKey(data: rawEncryptionKey)
        let aad = associatedData

        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: cipherText, tag: tag)
        return try AES.GCM.open(sealedBox, using: key, authenticating: aad)
    }

    /// Encodes the salt and encrypted data into a single payload with versioning.
    /// Format: [1-byte version] [4-byte salt length] [salt] [4-byte encrypted length] [encryptedData]
    private static func encode(salt: Data, encryptedData: Data) -> Data {
        var data = Data()
        data.append(Constants.encodeSchemeVersion)
        // Encodes an Int as a 4-byte big-endian UInt32.
        data.append(contentsOf: salt.count.bytes4)
        data.append(salt)
        // Encodes an Int as a 4-byte big-endian UInt32.
        data.append(contentsOf: encryptedData.count.bytes4)
        data.append(encryptedData)
        return data
    }

    /// Decodes the payload into salt and encrypted data.
    /// - Parameter data: The encoded payload.
    /// - Returns: A tuple containing the salt and encrypted data.
    /// - Throws: EncodingError if the version is unsupported or the payload is invalid.
    private static func decode(data: Data) throws -> (salt: Data, encryptedData: Data) {
        var cursor = data.startIndex

        // Read version
        guard data.count > cursor else {
            throw EncodingError.invalidPayload
        }
        let version = data[cursor]
        guard version == Constants.encodeSchemeVersion else {
            throw EncodingError.unsupportedVersion
        }
        cursor += 1

        // Read salt length
        guard data.count >= cursor + 4 else {
            throw EncodingError.invalidPayload
        }
        let saltLenData = data[cursor ..< cursor + 4]
        guard let saltLen = saltLenData.toInt() else {
            throw EncodingError.invalidPayload
        }
        cursor += 4

        guard data.count >= cursor + saltLen else {
            throw EncodingError.invalidPayload
        }
        let salt = data[cursor ..< cursor + saltLen]
        cursor += saltLen

        // Read encryptedData length
        guard data.count >= cursor + 4 else {
            throw EncodingError.invalidPayload
        }

        let encLenData = data[cursor ..< cursor + 4]

        guard let encLen = encLenData.toInt() else {
            throw EncodingError.invalidPayload
        }

        cursor += 4

        guard data.count >= cursor + encLen else {
            throw EncodingError.invalidPayload
        }

        let encrypted = data[cursor ..< cursor + encLen]

        return (salt: Data(salt), encryptedData: Data(encrypted))
    }

    /// Stretches a password into a cryptographic key using PBKDF2.
    /// - Parameters:
    ///   - password: The password to stretch.
    ///   - salt: The salt to use for key derivation.
    /// - Returns: The derived key as Data.
    /// - Throws: EncodingError if the password is invalid or stretching fails.
    private static func stretch(password: String, salt: Data) throws -> Data {
        guard let passwordData = password.data(using: .utf8), !passwordData.isEmpty else {
            throw EncodingError.invalidPassword
        }

        return try passwordData.pbkdf2sha256(
            salt: salt,
            rounds: Constants.iterations,
            keyByteCount: Constants.stretchedPasswordLengthBytes
        )
    }
}

/// Errors that can occur during encoding or encryption operations.
enum EncodingError: Error {
    case invalidPassword
    case invalidEncryptionKeyLength
    case invalidPayload
    case unsupportedVersion
}

extension AESEncoder {
    /// Constants used for encoding and encryption.
    enum Constants {
        static let possibleEncryptionKeyLengths: [Int] = [16, 24, 32]
        static let stretchedPasswordLengthBytes = 32
        static let encodeSchemeVersion: UInt8 = 1
        static let tagLengthBit = 128
        static let ivLengthByte = 12
        static let saltSize = 16
        static let minIterations = 1_000
        static let iterations = 600_000
    }
}
