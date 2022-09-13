//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 13/09/22.
//

import XCTest

class RemoteFeedLoader {
    let client: HTTPClient
    init(client: HTTPClient) {
        self.client = client
    }
    
    func load() {
        // We don't need to know or locate where the HTTPClient is, so we don't need the singleton
        // And it is best to use composition instead of singleton.
        client.get(from: URL(string: "https://a-url.com")!)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

// Move the test logic to a spy instead
class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
    func get(from url: URL) {
        // We're moving the test logic from the RemoteFeedLoader to HTTPClient
        requestedURL = url //--> This is the test logic. This is created for testing purposes
    }
}

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(client: client)
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestsDataFromURL() {
        // Arrange
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client)
        // Act
        sut.load()
        // Assert
        XCTAssertNotNil(client.requestedURL)
    }
}
