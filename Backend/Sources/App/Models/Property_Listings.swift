//
//  Property_Listings.swift
//  Backend_Property_Listing
//
//  Created by Issouf Diarrassouba on 12/2/24.

// NEED TO WORK WOITH RONT END TO DISPLAY THE OVERALL LISTINGS
    // Does it go obtain listings and straight to the db or does it go straight to the frontend then gets to the db ??

import SwiftUI
import Combine
import Vapor
import Fluent
import JWT


struct APIResponse: Decodable {
    let data: DataWrapper

    struct DataWrapper: Decodable {
        let results: [PropertyListing]
    }
}

struct PropertyListing: Content {
    let propertyId: String
    let listingId: String
    let listPrice: Double?
    let primaryPhoto: Photo?

    enum CodingKeys: String, CodingKey {
        case propertyId = "property_id"
        case listingId = "listing_id"
        case listPrice = "list_price"
        case primaryPhoto = "primary_photo"
    }
}

struct Photo: Content {
    let href: String
}
