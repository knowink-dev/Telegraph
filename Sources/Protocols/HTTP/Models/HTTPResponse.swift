//
//  HTTPResponse.swift
//  Telegraph
//
//  Created by Yvo van Beek on 1/31/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

open class HTTPResponse: HTTPMessage {
  public typealias Handler = (HTTPResponse, Error) -> Void

  public var status: HTTPStatus

  /// Initializes a new HTTPResponse
  public init(_ status: HTTPStatus = .ok, version: HTTPVersion = .default,
              headers: HTTPHeaders = .empty, body: Data = Data(), bodyFile: FileHandle? = nil) {
    self.status = status
    super.init(version: version, headers: headers, body: body, bodyFile: bodyFile)
  }

  /// Writes the first line of the response, e.g. HTTP/1.1 200 OK
  override internal var firstLine: String {
    return "\(version) \(status)"
  }

  /// Prepares the response to be written tot the stream
  override open func prepareForWrite() {
    super.prepareForWrite()

    // Set the date header
    headers.date = Date().rfc1123

    // Files set their content length in HTTPFileHandler
    if bodyFile == nil {
        // If a body is allowed set the content length (even when 0)
        if status.supportsBody {
          headers.contentLength = Int64(exactly: body.count)!
        } else {
          headers.contentLength = nil
          body.count = 0
        }
    }
  }
}

// MARK: Convenience initializers

extension HTTPResponse {
  /// Creates an HTTP response to send textual content.
  public convenience init(_ status: HTTPStatus = .ok, headers: HTTPHeaders = .empty, content: String) {
    self.init(status, headers: headers, body: content.utf8Data)
  }

  /// Creates an HTTP response to send an error.
  public convenience init(_ status: HTTPStatus = .internalServerError, headers: HTTPHeaders = .empty, error: Error) {
    var errorHeaders = headers
    errorHeaders.connection = "close"

    self.init(status, headers: errorHeaders, body: error.localizedDescription.utf8Data)
  }
}

// MARK: CustomStringConvertible

extension HTTPResponse: CustomStringConvertible {
  open var description: String {
    let typeName = type(of: self)
    return "<\(typeName): \(version) \(status), headers: \(headers.count), body: \(body.count) bodyFile: \(bodyFile?.description ?? "None")>"
  }
}

// MARK: Deprecated

extension HTTPResponse {
  @available(*, deprecated, message: "use DateFormatter.rfc1123 or Date's rfc1123 variable")
  public static let dateFormatter = DateFormatter.rfc1123

  @available(*, deprecated, message: "data: has been renamed to body:")
  public convenience init(_ status: HTTPStatus = .ok, data: Data) {
    self.init(status, body: data)
  }

  @available(*, deprecated, message: "use keepAlive instead, this setter only handles true properly")
  public var closeAfterWrite: Bool {
    get { return !keepAlive }
    set { if newValue { headers.connection = "close" } }
  }
}
