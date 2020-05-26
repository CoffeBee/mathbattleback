import LoggerAPI
import Health
import KituraContracts

func initializeHealthRoutes(app: App) {
    
    app.router.post("/add", handler: app.postHandler)
    app.router.get("/list", handler: app.getAllHandler)
}

extension App {
    static var codableStore = [Task]()
    func postHandler(book: Task, completion: (Task?, RequestError?) -> Void) {
        App.codableStore.append(book)
        completion(book, nil)
    }
    func getAllHandler(completion: ([Task]?, RequestError?) -> Void) {
        completion(App.codableStore, nil)
    }
}
