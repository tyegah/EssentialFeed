//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 13/09/22.
//

import XCTest

class RemoteFeedLoader {
    let client: HTTPClient
    let url: URL
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load() {
        // We don't need to know or locate where the HTTPClient is, so we don't need the singleton
        // And it is best to use composition instead of singleton.
        client.get(from: url)
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
        let url = URL(string: "https://a-given-url.com")!
        _ = RemoteFeedLoader(url: url, client: client)
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestsDataFromURL() {
        // Arrange
        let client = HTTPClientSpy()
        let url = URL(string: "https://a-given-url.com")!
        let sut = RemoteFeedLoader(url: URL(string: "https://a-given-url.com")!, client: client)
        // Act
        sut.load()
        // Assert
        XCTAssertEqual(client.requestedURL, url)
    }
}
