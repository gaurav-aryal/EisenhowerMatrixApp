//
//  ContentView.swift
//  EisenhowerMatrixApp
//
//  Created by user280681 on 8/2/25.
//  Copyright © 2025 EisenhowerMatrixApp. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var priority: TaskPriority
    var isCompleted: Bool = false
    var dateCreated: Date = Date()
    
    init(title: String, description: String, priority: TaskPriority) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.priority = priority
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.priority = try container.decode(TaskPriority.self, forKey: .priority)
        self.isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        self.dateCreated = try container.decode(Date.self, forKey: .dateCreated)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(priority, forKey: .priority)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(dateCreated, forKey: .dateCreated)
    }
    
    // Custom coding keys to handle UUID
    private enum CodingKeys: String, CodingKey {
        case id, title, description, priority, isCompleted, dateCreated
    }
    
}

enum TaskPriority: String, CaseIterable, Codable, Identifiable {
    case urgentImportant = "Urgent & Important"
    case urgentNotImportant = "Urgent & Not Important"
    case notUrgentImportant = "Not Urgent & Important"
    case notUrgentNotImportant = "Not Urgent & Not Important"

    var id: String { rawValue }
    
    var color: SwiftUI.Color {
        switch self {
        case .urgentImportant: return SwiftUI.Color.red
        case .urgentNotImportant: return SwiftUI.Color.orange
        case .notUrgentImportant: return SwiftUI.Color.blue
        case .notUrgentNotImportant: return SwiftUI.Color.gray
        }
    }
    
    /// Readable title split across lines for compact quadrant headers
    var displayTitle: String {
        switch self {
        case .urgentImportant:
            return "Urgent &\nImportant"
        case .urgentNotImportant:
            return "Urgent &\nNot Important"
        case .notUrgentImportant:
            return "Not Urgent &\nImportant"
        case .notUrgentNotImportant:
            return "Not Urgent &\nNot Important"
        }
    }
}

// MARK: - App Appearance
enum BackgroundMode: String, CaseIterable, Identifiable {
    case dark = "Dark"
    case gray = "Gray"
    case white = "White"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .dark:
            return .black
        case .gray:
            return .gray
        case .white:
            return .white
        }
    }
}

// MARK: - Data Manager
class TaskManager: ObservableObject {
    @Published var tasks: [TaskItem] = []
    private let userId: String

    init(userId: String) {
        self.userId = userId
        loadTasks()
        if tasks.isEmpty {
            loadSampleData()
        }
    }

    private func fileURL() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("tasks_\(userId).json")
    }

    private func loadTasks() {
        let url = fileURL()
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) else { return }
        tasks = decoded
    }

    private func saveTasks() {
        let url = fileURL()
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        try? data.write(to: url)
    }

    func addTask(title: String, description: String, priority: TaskPriority) {
        let newTask = TaskItem(
            title: title,
            description: description,
            priority: priority
        )
        tasks.append(newTask)
        saveTasks()
    }

    private func loadSampleData() {
        tasks = [
            // Urgent & Important - 7 tasks (will show 5 + "More...")
            TaskItem(title: "Deadline project", description: "Complete urgent project", priority: .urgentImportant),
            TaskItem(title: "Team meeting", description: "Prepare for meeting", priority: .urgentImportant),
            TaskItem(title: "Client presentation", description: "Prepare slides", priority: .urgentImportant),
            TaskItem(title: "Budget review", description: "Review quarterly budget", priority: .urgentImportant),
            TaskItem(title: "Emergency call", description: "Handle urgent client call", priority: .urgentImportant),
            TaskItem(title: "Project deadline", description: "Finalize project deliverables", priority: .urgentImportant),
            TaskItem(title: "Critical bug fix", description: "Fix production bug", priority: .urgentImportant),
            
            // Urgent & Not Important - 3 tasks (will show all 3)
            TaskItem(title: "Email responses", description: "Reply to emails", priority: .urgentNotImportant),
            TaskItem(title: "Phone calls", description: "Return calls", priority: .urgentNotImportant),
            TaskItem(title: "Meeting prep", description: "Prepare for team meeting", priority: .urgentNotImportant),
            
            // Not Urgent & Important - 4 tasks (will show all 4)
            TaskItem(title: "Strategic planning", description: "Plan goals", priority: .notUrgentImportant),
            TaskItem(title: "Skill development", description: "Learn technology", priority: .notUrgentImportant),
            TaskItem(title: "Network building", description: "Connect with colleagues", priority: .notUrgentImportant),
            TaskItem(title: "Process improvement", description: "Optimize workflows", priority: .notUrgentImportant),
            
            // Not Urgent & Not Important - 2 tasks (will show all 2)
            TaskItem(title: "Social media", description: "Check updates", priority: .notUrgentNotImportant),
            TaskItem(title: "Some interruptions", description: "Handle distractions", priority: .notUrgentNotImportant)
        ]
    }
    
    func toggleTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }

    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    func tasksForPriority(_ priority: TaskPriority) -> [TaskItem] {
        return tasks.filter { $0.priority == priority }
    }

    /// Returns only tasks that are not marked as completed for the given priority.
    func activeTasksForPriority(_ priority: TaskPriority) -> [TaskItem] {
        return tasks.filter { $0.priority == priority && !$0.isCompleted }
    }

    /// Returns only tasks that are completed for the given priority.
    func completedTasksForPriority(_ priority: TaskPriority) -> [TaskItem] {
        return tasks.filter { $0.priority == priority && $0.isCompleted }
    }

    func moveTask(_ task: TaskItem, to newPriority: TaskPriority) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].priority = newPriority
            saveTasks()
        }
    }

    func reorderTasks(from sourceIndex: Int, to destinationIndex: Int, in priority: TaskPriority) {
        let priorityTasks = tasksForPriority(priority)
        guard sourceIndex < priorityTasks.count && destinationIndex < priorityTasks.count else { return }

        let sourceTask = priorityTasks[sourceIndex]
        let destinationTask = priorityTasks[destinationIndex]

        // Find the actual indices in the main tasks array
        if let sourceIndexInMain = tasks.firstIndex(where: { $0.id == sourceTask.id }),
           let destIndexInMain = tasks.firstIndex(where: { $0.id == destinationTask.id }) {
            let task = tasks.remove(at: sourceIndexInMain)
            let adjustedDestination = sourceIndexInMain < destIndexInMain ? destIndexInMain - 1 : destIndexInMain
            tasks.insert(task, at: adjustedDestination)
            saveTasks()
        }
    }

    func updateTask(_ task: TaskItem, title: String, description: String, priority: TaskPriority) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].title = title
            tasks[index].description = description
            tasks[index].priority = priority
            saveTasks()
        }
    }
}

// MARK: - Drop Delegates
struct TaskDropDelegate: DropDelegate {
    let task: TaskItem
    let taskManager: TaskManager
    let currentPriority: TaskPriority
    @Binding var draggedTaskId: UUID?

    func dropEntered(_ info: DropInfo) {
        guard let draggedId = draggedTaskId,
              draggedId != task.id,
              let draggedTask = taskManager.tasks.first(where: { $0.id == draggedId }) else { return }

        if draggedTask.priority == currentPriority {
            let priorityTasks = taskManager.tasksForPriority(currentPriority)
            if let fromIndex = priorityTasks.firstIndex(where: { $0.id == draggedId }),
               let toIndex = priorityTasks.firstIndex(where: { $0.id == task.id }) {
                taskManager.reorderTasks(from: fromIndex, to: toIndex, in: currentPriority)
            }
        } else {
            taskManager.moveTask(draggedTask, to: currentPriority)
        }
    }

    func dropUpdated(_ info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedTaskId = nil
        return true
    }
}

struct QuadrantDropDelegate: DropDelegate {
    let priority: TaskPriority
    let taskManager: TaskManager
    @Binding var draggedTaskId: UUID?

    func dropUpdated(_ info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedId = draggedTaskId,
              let draggedTask = taskManager.tasks.first(where: { $0.id == draggedId }) else { return false }

        if draggedTask.priority == priority {
            let priorityTasks = taskManager.tasksForPriority(priority)
            if let fromIndex = priorityTasks.firstIndex(where: { $0.id == draggedId }) {
                taskManager.reorderTasks(from: fromIndex, to: priorityTasks.count - 1, in: priority)
            }
        } else {
            taskManager.moveTask(draggedTask, to: priority)
        }

        draggedTaskId = nil
        return true
    }
}

// MARK: - Content View
struct ContentView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var selectedPriority: TaskPriority?
    @State private var selectedPriorityForAdd: TaskPriority?
    @State private var selectedTask: TaskItem?
    @State private var showingAddTask = false
    @State private var showingTaskDetail = false
    @State private var isDragging = false
    @State private var draggedTaskId: UUID?
    @State private var backgroundMode: BackgroundMode = .white
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Eisenhower Matrix")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    HStack {
                        Image(systemName: "hand.draw")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Drag tasks between quadrants to change priority")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()

                Picker("Background", selection: $backgroundMode) {
                    ForEach(BackgroundMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Matrix Grid
                GeometryReader { geometry in
                    ZStack {
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                matrixQuadrant(priority: .urgentImportant, color: .red)
                                matrixQuadrant(priority: .urgentNotImportant, color: .orange)
                            }
                            HStack(spacing: 0) {
                                matrixQuadrant(priority: .notUrgentImportant, color: .blue)
                                matrixQuadrant(priority: .notUrgentNotImportant, color: .gray)
                            }
                        }
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            path.move(to: CGPoint(x: width / 2, y: 0))
                            path.addLine(to: CGPoint(x: width / 2, y: height))
                            path.move(to: CGPoint(x: 0, y: height / 2))
                            path.addLine(to: CGPoint(x: width, y: height / 2))
                        }
                        .stroke(Color.primary, lineWidth: 2)
                    }
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundMode.color.ignoresSafeArea())
        .preferredColorScheme(backgroundMode == .white ? .light : .dark)
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskManager: taskManager, priority: selectedPriorityForAdd ?? .urgentImportant)
        }
        .sheet(item: $selectedPriority) { priority in
            PriorityDetailView(taskManager: taskManager, priority: priority)
        }
        .sheet(isPresented: $showingTaskDetail) {
            if let task = selectedTask {
                TaskDetailView(task: task, taskManager: taskManager)
            }
        }
    }
    
    private func matrixQuadrant(priority: TaskPriority, color: Color) -> some View {
        let tasks = taskManager.activeTasksForPriority(priority)
        
        return VStack(spacing: 6) {
            // Header with title - clickable to open full list
            VStack(spacing: 4) {
                HStack {
                    Text(priority.displayTitle)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .onTapGesture {
                            selectedPriority = priority
                        }

                    Spacer()
                }
            }
            
            // Task list - individual tasks clickable
            VStack(alignment: .leading, spacing: 3) {
                ForEach(tasks.prefix(5)) { task in
                    HStack(spacing: 6) {
                        Button(action: {
                            taskManager.toggleTask(task)
                        }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : color)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())

                        VStack(alignment: .leading, spacing: 1) {
                            Text(task.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .strikethrough(task.isCompleted)
                                .lineLimit(1)
                                .onTapGesture {
                                    selectedTask = task
                                    showingTaskDetail = true
                                }

                            Text(task.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .onTapGesture {
                                    selectedTask = task
                                    showingTaskDetail = true
                                }
                        }

                        Spacer()

                        // Drag handle indicator
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(color.opacity(0.6))
                            .font(.caption2)

                        Button(action: {
                            taskManager.deleteTask(task)
                        }) {
                            Text("🗑️")
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                    .onDrag {
                        draggedTaskId = task.id
                        return NSItemProvider(object: task.id.uuidString as NSString)
                    }
                    .onDrop(of: [UTType.plainText], delegate: TaskDropDelegate(task: task, taskManager: taskManager, currentPriority: priority, draggedTaskId: $draggedTaskId))
                }

                HStack {
                    if tasks.count > 5 {
                        Button(action: {
                            selectedPriority = priority
                        }) {
                            Text("More...")
                                .font(.caption)
                                .foregroundColor(color)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Spacer()

                    Button(action: {
                        selectedPriorityForAdd = priority
                        showingAddTask = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(color)
                                .font(.caption)
                            Text("Add Task")
                                .font(.caption)
                                .foregroundColor(color)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .onDrop(of: [UTType.plainText], delegate: QuadrantDropDelegate(priority: priority, taskManager: taskManager, draggedTaskId: $draggedTaskId))
            Spacer()
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(0.1))
        .overlay(
            Rectangle()
                .stroke(color, lineWidth: 1)
        )
        .onDrop(of: [UTType.plainText], delegate: QuadrantDropDelegate(priority: priority, taskManager: taskManager, draggedTaskId: $draggedTaskId))
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @ObservedObject var taskManager: TaskManager
    let priority: TaskPriority
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Priority")) {
                    Text(priority.rawValue)
                        .foregroundColor(priority.color)
                        .fontWeight(.semibold)
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        taskManager.addTask(title: title, description: description, priority: priority)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Priority Detail View
struct PriorityDetailView: View {
    @ObservedObject var taskManager: TaskManager
    let priority: TaskPriority
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTask = false
    @State private var showCompleted = false

    var body: some View {
        let activeTasks = taskManager.activeTasksForPriority(priority)
        let completedTasks = taskManager.completedTasksForPriority(priority)

        return NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(priority.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(getSubtitle(for: priority))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    
                    HStack {
                        Text("\(activeTasks.count) tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(completedTasks.count) completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(priority.color.opacity(0.1))

                // Task List
                List {
                    ForEach(activeTasks) { task in
                        TaskRowView(task: task, taskManager: taskManager)
                    }
                    .onDelete(perform: deleteActiveTasks)

                    if !completedTasks.isEmpty {
                        DisclosureGroup(isExpanded: $showCompleted) {
                            ForEach(completedTasks) { task in
                                TaskRowView(task: task, taskManager: taskManager)
                            }
                            .onDelete(perform: deleteCompletedTasks)
                        } label: {
                            Text("Completed (\(completedTasks.count))")
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(priority.rawValue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Task") {
                        showingAddTask = true
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Edit") {
                        // Enable edit mode for reordering
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskManager: taskManager, priority: priority)
        }
    }
    
    private func getSubtitle(for priority: TaskPriority) -> String {
        switch priority {
        case .urgentImportant:
            return "Do First - These require immediate attention"
        case .urgentNotImportant:
            return "Delegate - These can be delegated to others"
        case .notUrgentImportant:
            return "Schedule - Plan these for later"
        case .notUrgentNotImportant:
            return "Eliminate - Consider removing these tasks"
        }
    }
    
    private func deleteActiveTasks(offsets: IndexSet) {
        let tasksToDelete = taskManager.activeTasksForPriority(priority)
        for index in offsets {
            taskManager.deleteTask(tasksToDelete[index])
        }
    }

    private func deleteCompletedTasks(offsets: IndexSet) {
        let tasksToDelete = taskManager.completedTasksForPriority(priority)
        for index in offsets {
            taskManager.deleteTask(tasksToDelete[index])
        }
    }
    
    private func moveTasks(from source: IndexSet, to destination: Int) {
        // Simple reordering within the same priority
        let priorityTasks = taskManager.tasksForPriority(priority)
        guard let sourceIndex = source.first, sourceIndex < priorityTasks.count else { return }
        
        // For now, just log the move operation
        print("Moving task from index \(sourceIndex) to destination \(destination)")
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: TaskItem
    @ObservedObject var taskManager: TaskManager
    @State private var showingEditTask = false
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedDescription: String
    
    init(task: TaskItem, taskManager: TaskManager) {
        self.task = task
        self.taskManager = taskManager
        self._editedTitle = State(initialValue: task.title)
        self._editedDescription = State(initialValue: task.description)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { taskManager.toggleTask(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    TextField("Task title", text: $editedTitle)
                        .font(.body)
                        .fontWeight(.medium)
                        .onSubmit {
                            taskManager.updateTask(task, title: editedTitle, description: editedDescription, priority: task.priority)
                            isEditing = false
                        }
                    
                    TextField("Description", text: $editedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .onSubmit {
                            taskManager.updateTask(task, title: editedTitle, description: editedDescription, priority: task.priority)
                            isEditing = false
                        }
                } else {
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                        .onTapGesture {
                            isEditing = true
                        }
                    
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .strikethrough(task.isCompleted)
                        .onTapGesture {
                            isEditing = true
                        }
                }
            }
            
            Spacer()
            
            Button(action: {
                showingEditTask = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(task.dateCreated, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(taskManager: taskManager, task: task)
        }
    }
}

// MARK: - Edit Task View
struct EditTaskView: View {
    @ObservedObject var taskManager: TaskManager
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var priority: TaskPriority
    
    init(taskManager: TaskManager, task: TaskItem) {
        self.taskManager = taskManager
        self.task = task
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description)
        self._priority = State(initialValue: task.priority)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue)
                                .foregroundColor(priority.color)
                                .tag(priority)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        taskManager.updateTask(task, title: title, description: description, priority: priority)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Task Detail View
struct TaskDetailView: View {
    let task: TaskItem
    @ObservedObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditTask = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Task Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.priority.rawValue)
                                .font(.headline)
                                .foregroundColor(task.priority.color)

                            Text(getSubtitle(for: task.priority))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    
                    HStack {
                        Text("Created: \(task.dateCreated, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            taskManager.toggleTask(task)
                        }) {
                            HStack {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.isCompleted ? .green : .gray)
                                Text(task.isCompleted ? "Completed" : "Mark Complete")
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(task.priority.color.opacity(0.1))
                .cornerRadius(12)
                
                // Task Content
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(task.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .strikethrough(task.isCompleted)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(task.description)
                            .font(.body)
                            .strikethrough(task.isCompleted)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Task Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEditTask = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(taskManager: taskManager, task: task)
        }
    }
    
    private func getSubtitle(for priority: TaskPriority) -> String {
        switch priority {
        case .urgentImportant:
            return "Do First - These require immediate attention"
        case .urgentNotImportant:
            return "Delegate - These can be delegated to others"
        case .notUrgentImportant:
            return "Schedule - Plan these for later"
        case .notUrgentNotImportant:
            return "Eliminate - Consider removing these tasks"
        }
    }
}


#Preview {
    ContentView(taskManager: TaskManager(userId: "preview"))
}
