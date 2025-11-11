//
//  HslApi.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import Foundation

class HslApi {
    
    static let shared = HslApi()
    
    private let routingUrl = "https://api.digitransit.fi/routing/v2/hsl/gtfs/v1?digitransit-subscription-key="

    private let apiKey = "877adb1ee87e4aae9a7ff5fe39b2502b"
        
    enum HslApiError: Error {
        case invalidURL
        // Add more error cases as needed
    }
    
    
    func fetchAllStops() async -> [Stop] {
        let query = """
        {
          stops {
            gtfsId
            name
            code
            lat
            lon
          }
        }
        """
        do {
            let request = try buildRequest(query: query)
            let (data, _) = try await URLSession.shared.data(for: request)
            if let decodedResponse = try? JSONDecoder().decode(StopsQueryResponse.self, from: data) {
                var result = [Stop]()
                let stops = decodedResponse.data.stops
                for stop in stops {
                    let newStop = Stop(id: stop.gtfsId, name: stop.name, code: stop.code ?? "No code", latitude: stop.lat, longitude: stop.lon)
                    result.append(newStop)
                }
                return result
            }
        } catch {
            print("Error requesting data")
        }
        return []
    }
    
    
    func fetchDepartures(stationId: String, numberOfResults: Int) async -> [Departure] {
                
        let query = """
            {
                stop(id:\"\(stationId)\"){
                    stoptimesWithoutPatterns(numberOfDepartures: \(numberOfResults)) {
                        realtimeDeparture
                        serviceDay
                        headsign
                        trip{
                          route {
                            mode
                            shortName
                          }
                        }
                    }
                }
            }
            """
        do {
            let request = try buildRequest(query: query)
            let (data, _) = try await URLSession.shared.data(for: request)
            if let decodedResponse = try? JSONDecoder().decode(DepartureTimesQueryResponse.self, from: data) {
                var result = [Departure]()
                for stopTime in decodedResponse.data.stop.stoptimesWithoutPatterns {
                    let departureTimeStamp = stopTime.serviceDay + stopTime.realtimeDeparture
                    let date = Date(timeIntervalSince1970: departureTimeStamp)
                    let shortName = stopTime.trip.route.shortName
                    let headsign = stopTime.headsign
                    let departure = Departure(departureTime: date, routeShortName: shortName,
                        headsign: headsign ?? "No headsign")
                    result.append(departure)
                }
                return result
            }
        } catch {
            print("Error requesting data")
        }
        return []
    }

    private func buildRequest(query: String) throws -> URLRequest {
        guard let url = URL(string: routingUrl + apiKey) else {
            print("Invalid URL")
            throw HslApiError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = query.data(using: .utf8)
        request.setValue("application/graphql", forHTTPHeaderField: "Content-Type")
        return request
    }

}
