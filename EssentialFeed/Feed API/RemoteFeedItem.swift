//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 26/09/22.
//

import Foundation

// To match with the local counterpart (LocalFeedLoader)
// We add another data transfer model for the remote data to remove its dependency from FeedItem model
internal struct RemoteFeedItem:Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
