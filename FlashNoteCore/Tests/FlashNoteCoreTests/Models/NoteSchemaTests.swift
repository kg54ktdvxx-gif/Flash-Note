import Testing
import SwiftData
@testable import FlashNoteCore

@Suite("NoteSchema")
struct NoteSchemaTests {

    @Test("SchemaV1 version identifier is 1.0.0")
    func versionIdentifier() {
        #expect(NoteSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
    }

    @Test("SchemaV1 includes Note model")
    func includesNoteModel() {
        let models = NoteSchemaV1.models
        #expect(models.count == 1)
        #expect(models[0] is Note.Type)
    }

    @Test("MigrationPlan includes SchemaV1")
    func migrationPlanSchemas() {
        let schemas = NoteMigrationPlan.schemas
        #expect(schemas.count == 1)
    }

    @Test("MigrationPlan has no stages yet")
    func migrationPlanStages() {
        #expect(NoteMigrationPlan.stages.isEmpty)
    }

    @Test("ModelContainer can be created with migration plan")
    func containerWithMigrationPlan() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Schema([Note.self]),
            migrationPlan: NoteMigrationPlan.self,
            configurations: [config]
        )
        #expect(container.schema.entities.count >= 1)
    }
}
