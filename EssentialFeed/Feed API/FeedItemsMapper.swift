//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 16/09/22.
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

final class FeedItemsMapper {
    private struct Root:Decodable {
        let items: [RemoteFeedItem]
    }
    
    private static var OK_200: Int {
        return 200
    }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}
