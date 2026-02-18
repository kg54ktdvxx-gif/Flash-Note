import SwiftData

public enum NoteSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [Note.self]
    }
}

public enum NoteMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [NoteSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        // No migrations needed yet — v1 is the initial schema.
        // When Note's schema changes, add a MigrationStage here.
        []
    }
}
