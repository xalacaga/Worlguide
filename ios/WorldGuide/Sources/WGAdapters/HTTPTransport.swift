import Foundation

/// Narrow seam around `URLSession` so adapters in this module can be tested
/// against a fake instead of `URLProtocol` mocking. `WGAdapters` is the only
/// module allowed to import a network client (docs/adr/0003, docs/adr/0012).
public protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport {}
