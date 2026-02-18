
protocol ExpressDestinationNotificationProvider {
    func validate(destination: String) async -> ValidationError?
}
