//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 13/09/22.
//

import Foundation

public protocol HTTPClient {
   func get(from url: URL)
}

public class RemoteFeedLoader {
    private let client: HTTPClient
    private let url: URL
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load() {
        // We don't need to know or locate where the HTTPClient is, so we don't need the singleton
        // And it is best to use composition instead of singleton.
        client.get(from: url)
    }
}
