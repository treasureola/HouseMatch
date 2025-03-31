//
//  Property.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 1/29/25.
//


import Foundation

struct Property: Identifiable {
    let id: String
    let propertyID: String
    let listingID: String
    let listingURL: String
    let status: String
    let imageUrl: String
    let address: String
    let location: String
    let price: Int
    let bedrooms: Int
    let bathrooms: Int
    let squareFeet: Int
    let amenities: [String]
    let petFriendly: Bool
//    let recommendationScore: Float
}
