//
//  ReferralView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReferralView: View {
    @ObservedObject var viewModel: ReferralViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Assets.referralDude
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, 40)
                    .frame(maxHeight: 222)

                Text("referral_title".localized)
                    .font(Fonts.Bold.title1)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 57)
                    .padding(.top, 28)
                    .padding(.bottom, 32)

                content

                Spacer()
            }
        }
        .navigationBarTitle("details_referral_title".localized)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    var content: some View {
        if !viewModel.isLoading, viewModel.isProgramInfoLoaded {
            referralContent
        } else {
            loaderContent
        }
    }

    @ViewBuilder
    var referralContent: some View {
        VStack {
            ReferralPointView(
                Assets.cryptocurrencies,
                header: { Text("referral_point_currencies_title") },
                body: {
                    Text("referral_point_currencies_description_prefix") +
                        Text(viewModel.award).foregroundColor(Colors.Text.primary1) +
                        Text("referral_point_currencies_desxcription_suffix") +
                        Text(viewModel.referralInfo?.address ?? "")
                }
            )

            ReferralPointView(
                Assets.discount,
                header: { Text("referral_point_discount_title") },
                body: {
                    Text("referral_point_discount_description_prefix") +
                        Text(viewModel.discount).foregroundColor(Colors.Text.primary1) +
                        Text("referral_point_discount_description_suffix")
                })
                .padding(.top, viewModel.isAlreadyReferral ? 20 : 38)

            if viewModel.isAlreadyReferral {
                Spacer()

                HStack {
                    Text("referral_friends_bought_title")

                    Spacer()

                    Text(viewModel.numberOfWalletsBought)
                }
                .padding(16)
                .background(Colors.Background.primary)
                .cornerRadius(14)
                .padding(.top, 24)

                VStack(spacing: 8) {
                    Text("referral_promo_code_title")
                        .font(Fonts.Bold.footnote)
                        .foregroundColor(Colors.Text.tertiary)

                    Text(viewModel.promoCode)
                        .font(Fonts.Regular.title1)
                        .foregroundColor(Colors.Text.primary1)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Colors.Background.primary)
                .cornerRadius(14)
                .padding(.top, 14)

                HStack(spacing: 12) {
                    TangemButton(title: "common_copy",
                                 systemImage: "square.on.square",
                                 iconPosition: .leading,
                                 iconPadding: 10,
                                 action: viewModel.copyPromoCode)
                        .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                                       layout: .flexibleWidth))

                    TangemButton(title: "common_share",
                                 systemImage: "arrowshape.turn.up.forward",
                                 iconPosition: .leading,
                                 iconPadding: 10,
                                 action: viewModel.sharePromoCode)
                        .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                                       layout: .flexibleWidth))
                }
                .padding(.top, 14)

                touButton
            } else {
                Spacer()

                touButton

                TangemButton(
                    title: "referral_button_participate",
                    image: "tangemIcon",
                    iconPosition: .trailing,
                    iconPadding: 10,
                    action: viewModel.participateInReferralProgram
                )
                .buttonStyle(
                    TangemButtonStyle(colorStyle: .black,
                                      layout: .flexibleWidth,
                                      isLoading: viewModel.isLoading)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 44)
    }

    @ViewBuilder
    var loaderContent: some View {
        VStack(alignment: .leading, spacing: 38) {
            ReferralPlaceholderPointView(icon: Assets.cryptocurrencies)

            ReferralPlaceholderPointView(icon: Assets.discount)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    var touButton: some View {
        Button(action: viewModel.openTou) {
            Text(viewModel.touButtonPrefix) +
                Text("common_terms_and_conditions").foregroundColor(Colors.Text.accent) +
                Text("referral_tou_suffix")
        }
        .font(Fonts.Regular.footnote)
        .foregroundColor(Colors.Text.tertiary)
        .padding(.horizontal, 18)
    }
}

struct ReferralView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReferralView(
                viewModel: ReferralViewModel(coordinator: ReferralCoordinator(),
                                             json: referralJson)
            )
        }
    }
}

private let referralJson = """
{
    "conditions": {
        "award": 760,
        "discount": 40,
        "discountType": "percentage",
        "touLink": "https://tangem.com/xxx.html",
        "tokens": [
            {
                "id": "busdId",
                "name": "Binance USD",
                "symbol": "BUSD",
                "networkId": "binance-smart-chain",
                "contractAddress": "0x85eac5ac2f758618dfa09bdbe0cf174e7d574d5b",
                "decimalCount": 18
            },
            {
                "id": "busdId",
                "name": "Binance USD",
                "symbol": "BUSD",
                "networkId": "solana",
                "contractAddress": "0x85eac5ac2f758618dfa7654be0cf174e7d574d5b",
                "decimalCount": 18
            }
        ]
    },
    "referral": {
        "shareLink": "",
        "address": "0x1dac9...39583000",
        "promoCode": "x4JdK9",
        "walletPurchase": 5
    }
}
"""

private let notReferralJson = """
{
    "conditions": {
        "award": 10,
        "discount": 10,
        "discountType": "percentage",
        "touLink": "https://tangem.com/xxx.html",
        "tokens": [
            {
                "id": "busdId",
                "name": "Binance USD",
                "symbol": "BUSD",
                "networkId": "binance-smart-chain",
                "contractAddress": "0x85eac5ac2f758618dfa09bdbe0cf174e7d574d5b",
                "decimalCount": 18
            },
            {
                "id": "busdId",
                "name": "Binance USD",
                "symbol": "BUSD",
                "networkId": "solana",
                "contractAddress": "0x85eac5ac2f758618dfa7654be0cf174e7d574d5b",
                "decimalCount": 18
            }
        ]
    }
}
"""
