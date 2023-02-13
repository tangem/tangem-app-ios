//
//  Address.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import MobileBuySDK
import CoreLocation
import Contacts

struct Address {
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let country: String?
    let province: String?
    let zip: String?
    let firstName: String?
    let lastName: String?
    let phone: String?

    init(_ address: Storefront.MailingAddress) {
        addressLine1 = address.address1
        addressLine2 = address.address2
        city = address.city
        country = address.country
        province = address.province
        self.zip = address.zip

        firstName = address.firstName
        lastName = address.lastName
        phone = address.phone
    }

    init(_ address: PayAddress) {
        addressLine1 = address.addressLine1
        addressLine2 = address.addressLine2
        city = address.city
        country = address.country
        province = address.province
        self.zip = address.zip

        firstName = address.firstName
        lastName = address.lastName
        phone = address.phone
    }

    init(_ address: PayPostalAddress) {
        city = address.city
        country = address.country
        province = address.province
        self.zip = address.zip

        addressLine1 = nil
        addressLine2 = nil
        firstName = nil
        lastName = nil
        phone = nil
    }

    init(_ address: CNPostalAddress) {
        country = address.country
        province = address.state
        city = address.city
        addressLine1 = address.street
        addressLine2 = address.subLocality
        self.zip = address.postalCode

        firstName = nil
        lastName = nil
        phone = nil
    }
}

extension Address {
    var payAddress: PayAddress {
        PayAddress(
            addressLine1: addressLine1,
            addressLine2: addressLine2,
            city: city,
            country: country,
            firstName: firstName,
            lastName: lastName,
            phone: phone
        )
    }

    var mutationInput: Storefront.MailingAddressInput {
        .create(
            address1: .init(orUndefined: addressLine1),
            address2: .init(orUndefined: addressLine2),
            city: .init(orUndefined: city),
            country: .init(orUndefined: country),
            firstName: .init(orUndefined: firstName),
            lastName: .init(orUndefined: lastName),
            phone: .init(orUndefined: phone),
            province: .init(orUndefined: province),
            zip: .init(orUndefined: zip)
        )
    }
}

extension Storefront.MailingAddressQuery {
    @discardableResult
    func addressFieldsFragment() -> Storefront.MailingAddressQuery {
        address1()
            .address2()
            .city()
            .country()
            .firstName()
            .lastName()
            .phone()
            .province()
            .zip()
    }
}
