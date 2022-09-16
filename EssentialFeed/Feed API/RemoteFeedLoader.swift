//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 13/09/22.
//

import Foundation

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = Swift.Result<[FeedItem], Error>
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        // We don't need to know or locate where the HTTPClient is, so we don't need the singleton
        // And it is best to use composition instead of singleton.
        client.get(from: url) { [weak self]
            result in
            // This line is important to prevent the result to be delivered after the instance is deallocated
            guard self != nil else { return }
            switch result {
            case let .success((data, response)):
                completion(FeedItemsMapper.map(data, response))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
