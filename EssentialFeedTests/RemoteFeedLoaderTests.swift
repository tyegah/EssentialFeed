//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 13/09/22.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        // Arrange
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        // Act
        sut.load()
        // Assert
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        // Arrange
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        // Act
        sut.load()
        sut.load()
        // Assert
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        // Arrange
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        // Act
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load() {
            capturedErrors.append($0)
        }
        
        // This behavior is called stubbing (stubbing error), adding behavior to a class
        // So now we're mixing the spy with a stub behavior, and we should only keep the spy as a spy.
//        client.error = NSError(domain: "", code: 0)
        // And we change the stubbed error with this to keep the spy as a spy, no behavior
        // And this is how the order should be. The completions should be arranged after the sut.load()
        let clientError = NSError(domain: "", code: 0)
        client.completions[0](clientError)
       
        // Assert
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    // MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    // Move the test logic to a spy instead
    class HTTPClientSpy: HTTPClient {
        var requestedURLs:[URL] = []
        var completions = [(Error) -> Void]()
        var error:Error?
        
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            completions.append(completion)
            // We're moving the test logic from the RemoteFeedLoader to HTTPClient
            requestedURLs.append(url) //--> This is the test logic. This is created for testing purposes
            
        }
    }
}
