//
//  ContentView.swift
//  CS4261CodingAssignment
//
//  Created by Jeff Rothwell on 9/2/25.
//

import SwiftUI

// MARK: - Weather Models
struct WeatherResponse: Codable {
    let list: [Forecast]
}

struct RawWeatherResponse: Codable {
    let forecasts: [RawForecast]
}

struct RawForecast: Codable {
    let date: String
    let temperature: Double
    let description: String
}

struct Forecast: Codable {
    let dt_txt: String
    let main: Main
    let weather: [Weather]
    
}

extension Forecast {
    init(from raw: RawForecast) {
        self.dt_txt = raw.date
        self.main = Main(temp: raw.temperature)
        self.weather = [Weather(description: raw.description)]
    }
}

struct Main: Codable {
    let temp: Double
}

struct Weather: Codable {
    let description: String
}


// MARK: - ContentView
struct ContentView: View {
    @State private var city: String = ""
    @State private var forecasts: [Forecast] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Enter city name", text: $city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button("Fetch Weather") {
                    fetchWeather(for: city) { result in
                        switch result {
                        case .success(let response):
                            forecasts = response.list
                            errorMessage = nil
                        case .failure(let error):
                            forecasts = []
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                .padding()

                if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                List(forecasts, id: \.dt_txt) { forecast in
                    VStack(alignment: .leading) {
                        Text(forecast.dt_txt)
                            .font(.headline)
                        Text("\(forecast.main.temp, specifier: "%.1f")°C")
                        Text(forecast.weather.first?.description.capitalized ?? "")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Weather Peek")
        }
    }
}

// MARK: - API Call
func fetchWeather(for city: String, completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
    let mobileApiKey = "c29tZWhvd2NpcmNsZXNob3dub2J0YWluc3Bpcml0ZGF3bmFyb3VuZHRoZXlzaG91bGQ"
    let urlString = "https://weather-api-1031436540785.us-east1.run.app/api/weather?city=\(city)"
    // You can also add state and country by appending "&state=\(state)&country=\(country)" to the URL
    

    guard let url = URL(string: urlString) else {
        completion(.failure(NSError(domain: "Invalid URL", code: 0)))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(mobileApiKey, forHTTPHeaderField: "X-API-Key")

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "No data", code: 0)))
            return
        }
        print(String(data: data, encoding: .utf8) ?? "Invalid JSON")

        do {
            let raw = try JSONDecoder().decode(RawWeatherResponse.self, from: data)
            let adaptedForecasts = raw.forecasts.map { Forecast(from: $0) }
            let wrapped = WeatherResponse(list: adaptedForecasts)
            DispatchQueue.main.async {
                completion(.success(wrapped))
            }
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

#Preview {
    ContentView()
}
