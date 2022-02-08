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
        self.addressLine1 = address.address1
        self.addressLine2 = address.address2
        self.city         = address.city
        self.country      = address.country
        self.province     = address.province
        self.zip          = address.zip

        self.firstName    = address.firstName
        self.lastName     = address.lastName
        self.phone        = address.phone
    }
    
    init(_ address: PayAddress) {
        self.addressLine1 = address.addressLine1
        self.addressLine2 = address.addressLine2
        self.city         = address.city
        self.country      = address.country
        self.province     = address.province
        self.zip          = address.zip

        self.firstName    = address.firstName
        self.lastName     = address.lastName
        self.phone        = address.phone
    }
    
    init(_ address: PayPostalAddress) {
        self.city = address.city
        self.country = address.country
        self.province = address.province
        self.zip = address.zip
        
        self.addressLine1 = nil
        self.addressLine2 = nil
        self.firstName = nil
        self.lastName = nil
        self.phone = nil
    }
    
    init(_ address: CNPostalAddress) {
        self.country = address.country
        self.province = address.state
        self.city = address.city
        self.addressLine1 = address.street
        self.addressLine2 = address.subLocality
        self.zip = address.postalCode
        
        self.firstName = nil
        self.lastName = nil
        self.phone = nil
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

#warning("TODO")
extension Storefront.MailingAddressQuery {
    @discardableResult
    func addressFieldsFragment() -> Storefront.MailingAddressQuery {
        self
            .address1()
            .address2()
            .city()
//            .company()
            .country()
//            .countryCodeV2()
            .firstName()
//            .formatted()
//            .formattedArea()
//            .id()
            .lastName()
//            .latitude()
//            .longitude()
//            .name()
            .phone()
            .province()
//            .provinceCode()
            .zip()
    }
}
