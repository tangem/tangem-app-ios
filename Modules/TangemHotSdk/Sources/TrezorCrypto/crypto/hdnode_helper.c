//
//  hdnode_helper.c
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

#include <string.h>

#include <TrezorCrypto/hdnode_helper.h>
#include <TrezorCrypto/bip39.h>
#include <TrezorCrypto/bip32.h>
#include <TrezorCrypto/memzero.h>
#include <TrezorCrypto/cardano.h>

#define MNEMONIC_BUF_SIZE 256
#define SEED_BUF_SIZE 64

#define CARDANO_SECRET_LEN 96

bool entropy_to_seed(const uint8_t *entropy, int entropy_len, const char *passphrase, uint8_t out_seed[SEED_BUF_SIZE]) {
    char mnemonic[MNEMONIC_BUF_SIZE] = {0};
    
    // Generate mnemonic
    const char *mnemonic_result = mnemonic_from_data(entropy, entropy_len, mnemonic, MNEMONIC_BUF_SIZE);
    if (mnemonic_result == NULL) {
        return false;
    }
    
    // Generate seed
    mnemonic_to_seed(mnemonic, passphrase, out_seed, NULL);
    
    memzero(mnemonic, sizeof(mnemonic));
    
    return true;
}

bool entropy_to_hdnode(const uint8_t *entropy,
                       int entropy_len,
                       const char *passphrase,
                       const char *curve,
                       const uint32_t *derivation_indicies,
                       int derivation_indicies_len,
                       HDNode *out_node) {
    uint8_t out_seed[SEED_BUF_SIZE] = {0};
    
    // Convert entropy + passphrase to seed
    if (!entropy_to_seed(entropy, entropy_len, passphrase, out_seed)) {
        return false;
    };
    
    // Convert seed to HDNode
    if (hdnode_from_seed(out_seed, SEED_BUF_SIZE, curve, out_node) != 1) {
        memzero(out_seed, SEED_BUF_SIZE);
        return false;
    }
    
    memzero(out_seed, SEED_BUF_SIZE);
    
    // Derive the HDNode using the provided derivation indices
    for (int i = 0; i < derivation_indicies_len; i++) {
        uint32_t index = derivation_indicies[i];
        
        if (hdnode_private_ckd(out_node, index) != 1) {
            return false;
        }
    }
    
    return true;
}

bool entropy_to_hdnode_cardano(const uint8_t *entropy,
                               int entropy_len,
                               const char *passphrase,
                               const uint32_t *derivation_indicies,
                               int derivation_indicies_len,
                               HDNode *out_node) {
    uint8_t secret[CARDANO_SECRET_LEN] = {0};
    
    // Convert entropy + passphrase to extended secret (Icarus)
    if (secret_from_entropy_cardano_icarus((const uint8_t *)passphrase,
                                           (int)strlen(passphrase),
                                           entropy,
                                           entropy_len,
                                           secret,
                                           NULL) != 1) {
        return false;
    }
    
    // Convert secret to HDNode
    if (!hdnode_from_secret_cardano(secret, out_node)) {
        memzero(secret, CARDANO_SECRET_LEN);
        return false;
    }
    
    memzero(secret, CARDANO_SECRET_LEN);
    
    // Derive the HDNode using the provided derivation indices
    for (int i = 0; i < derivation_indicies_len; i++) {
        uint32_t index = derivation_indicies[i];
        
        if (hdnode_private_ckd_cardano(out_node, index) != 1) {
            return false;
        }
    }
    
    return true;
}
