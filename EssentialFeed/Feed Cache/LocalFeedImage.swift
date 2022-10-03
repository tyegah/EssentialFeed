//
//  LocalFeedIten.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 26/09/22.
//

import Foundation

// We start using this LocalFeedItem for 'FeedStore' instead of the FeedItem model to decentralized components (eliminating arrows pointing to the FeedItem model in the module diagram)
// This object is usually called Data Transfer Object (DTO) model
// So whenever there are changes in the FeedItem, this module will not be affected

//*** The codable conformance here is leaking framework details into the Feed Cache Module
//*** The solution is to create a framework specific model inside the CodableFeedStore
public struct LocalFeedImage:Equatable, Codable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL
    
    public init(id: UUID,
                description: String?,
                location: String?,
                url: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
}
