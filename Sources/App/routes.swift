import Vapor

public func routes(_ router: Router) throws {
    try ProfileController().boot(router: router)
}
