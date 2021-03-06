//
//  HTTPMessage+WebSocket.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/16/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

extension HTTPMessage {
  public static let webSocketProtocol = "websocket"
  public static let webSocketVersion = "13"
  fileprivate static let webSocketMagicGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  /// Is this an upgrade to the WebSocket protocol?
  var isWebSocketUpgrade: Bool {
    return headers.upgrade?.caseInsensitiveCompare(HTTPMessage.webSocketProtocol) == .orderedSame
  }
}

extension HTTPRequest {
  /// Creates a websocket handshake request.
  static func webSocketHandshake(host: String, port: Int = 80, protocolName: String = "") -> HTTPRequest {
    let request = HTTPRequest()
    request.webSocketHandshake(host: host, port: port, protocolName: protocolName)
    return request
  }

  /// Decorates a request with websocket handshake headers.
  func webSocketHandshake(host: String, port: Int = 80, protocolName: String = "") {
    method = .GET
    setHostHeader(host: host, port: port)

    headers.connection = "Upgrade"
    headers.upgrade = HTTPMessage.webSocketProtocol
    headers.webSocketKey = Data(randomNumberOfBytes: 16).base64EncodedString()
    headers.webSocketProtocol = protocolName
    headers.webSocketVersion = HTTPMessage.webSocketVersion
  }
}

public extension HTTPResponse {
  /// Creates a websocket handshake request.
  static func webSocketHandshake(key: String, protocolName: String = "") -> HTTPResponse {
    let response = HTTPResponse()
    response.webSocketHandshake(key: key, protocolName: protocolName)
    return response
  }

  /// Decorates a response with websocket handshake headers.
  func webSocketHandshake(key: String, protocolName: String = "") {
    // Take the incoming key, append the static GUID and return a base64 encoded SHA-1 hash
    let webSocketKey = key.appending(HTTPMessage.webSocketMagicGUID)
    let webSocketAccept = SHA1.hash(webSocketKey).base64EncodedString()

    status = .switchingProtocols
    headers.connection = "Upgrade"
    headers.upgrade = HTTPMessage.webSocketProtocol
    headers.webSocketAccept = webSocketAccept
    headers.webSocketProtocol = protocolName
  }

  // Returns a boolean indicating if the response is a websocket handshake.
  var isWebSocketHandshake: Bool {
    return status == .switchingProtocols && isWebSocketUpgrade &&
      headers.webSocketAccept?.isEmpty == false
  }
}
