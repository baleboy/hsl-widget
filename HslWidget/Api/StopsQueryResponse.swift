//
//  FetchStopsResponse.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 8.5.2024.
//

// Define the Stop structure
struct StopInfo: Codable {
    let gtfsId: String
    let name: String
    let code: String?
}

// Define a structure for the container of stops
struct StopsContainer: Codable {
    let stops: [StopInfo]
}

// Define the top-level structure matching the JSON response
struct StopsQueryResponse: Codable {
    let data: StopsContainer
}
