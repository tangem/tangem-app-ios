//
//  UserWalletId+Constants.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

extension UserWalletId {
    var privateInfoTag: String {
        Constants.privateInfoPrefix + stringValue
    }

    var privateInfoSecureEnclaveTag: String {
        Constants.privateInfoSecureEnclavePrefix + stringValue
    }

    var encryptionKeyTag: String {
        Constants.encryptionKeyPrefix + stringValue
    }

    var encryptionKeySecureEnclaveTag: String {
        Constants.encryptionKeySecureEnclavePrefix + stringValue
    }

    var encryptionKeyBiometricsTag: String {
        Constants.encryptionKeyBiometricsPrefix + stringValue
    }

    var encryptionKeyBiometricsSecureEnclaveTag: String {
        Constants.encryptionKeyBiometricsSecureEnclavePrefix + stringValue
    }

    var publicInfoTag: String {
        Constants.publicInfoPrefix + stringValue
    }

    var publicInfoSecureEnclaveTag: String {
        Constants.publicInfoSecureEnclavePrefix + stringValue
    }

    var publicInfoBiometricsTag: String {
        Constants.publicInfoBiometricsPrefix + stringValue
    }

    var publicInfoBiometricsSecureEnclaveTag: String {
        Constants.publicInfoBiometricsSecureEnclavePrefix + stringValue
    }
}

extension UserWalletId {
    enum Constants {
        static let privateInfoPrefix = "mobile_sdk_private_info_"
        static let privateInfoSecureEnclavePrefix = "mobile_sdk_private_info_secure_enclave_"
        static let encryptionKeyPrefix = "mobile_sdk_encryption_key_"
        static let encryptionKeySecureEnclavePrefix = "mobile_sdk_encryption_key_secure_enclave_"
        static let encryptionKeyBiometricsPrefix = "mobile_sdk_encryption_key_biometrics_"
        static let encryptionKeyBiometricsSecureEnclavePrefix = "mobile_sdk_encryption_key_biometrics_secure_enclave_"
        static let publicInfoPrefix = "mobile_sdk_public_info_"
        static let publicInfoSecureEnclavePrefix = "mobile_sdk_public_info_secure_enclave_"
        static let publicInfoBiometricsPrefix = "mobile_sdk_public_info_biometrics_"
        static let publicInfoBiometricsSecureEnclavePrefix = "mobile_sdk_public_info_biometrics_secure_enclave_"
    }
}
