import Foundation
import EventKit

class CalendarService: ObservableObject {
    @Published var upcomingEvents: [CalendarEventData] = []
    private let eventStore = EKEventStore()
    
    init() {
        requestCalendarAccess()
    }
    
    private func requestCalendarAccess() {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            if granted {
                self?.fetchUpcomingEvents()
            } else {
                // Load mock events for demo
                DispatchQueue.main.async {
    
                }
            }
        }
    }
    
    private func fetchUpcomingEvents() {
        let calendars = eventStore.calendars(for: .event)
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        
        DispatchQueue.main.async {
            self.upcomingEvents = events.prefix(3).map { event in
                CalendarEventData(
                    title: event.title,
                    startDate: event.startDate,
                    isAllDay: event.isAllDay
                )
            }
        }
    }
} 