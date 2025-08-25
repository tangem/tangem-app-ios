//
//  hdnode_helper.h
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

#ifndef hdnode_helper_h
#define hdnode_helper_h

#include <stdio.h>
#include <TrezorCrypto/bip32.h>

#endif /* hdnode_helper_h */

#ifdef __cplusplus
extern "C" {
#endif

bool entropy_to_hdnode(const uint8_t *entropy,
                       int entropy_len,
                       const char *passphrase,
                       const char *curve,
                       const uint32_t *derivation_indicies,
                       int derivation_indicies_len,
                       HDNode *out_node);
bool entropy_to_hdnode_cardano(const uint8_t *entropy,
                               int entropy_len,
                               const char *passphrase,
                               const uint32_t *derivation_indicies,
                               int derivation_indicies_len,
                               HDNode *out_node);

#ifdef __cplusplus
} /* extern "C" */
#endif
