import qbs

Project {
    name: "Unit Tests"
    references: [
        "Domain/domain.qbs",
        "Infrastructure/infrastructure.qbs",
        "Presentation/presentation.qbs"
    ]

    AutotestRunner {
        name: "unittests-runner"
        limitToSubProject: true
    }
}