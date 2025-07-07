flowchart TB
    %% Flutter Client Layer
    subgraph "Flutter Client" 
        direction TB
        UI["Pages & Widgets"]:::frontend
        click UI "https://github.com/okwama/woosh/tree/master/lib/pages/"
        Widgets["Widgets"]:::frontend
        click Widgets "https://github.com/okwama/woosh/tree/master/lib/widgets/"
        Controllers["GetX Controllers"]:::controllers
        click Controllers "https://github.com/okwama/woosh/tree/master/lib/controllers/"
        Services["ApiService & Services"]:::service
        click Services "https://github.com/okwama/woosh/blob/master/lib/services/api_service.dart"
        Models["Models"]:::models
        click Models "https://github.com/okwama/woosh/tree/master/lib/models/"
        Utils["Utilities"]:::utils
        click Utils "https://github.com/okwama/woosh/tree/master/lib/utils/"
        Routing["Routing"]:::routes
        click Routing "https://github.com/okwama/woosh/blob/master/lib/routes/app_routes.dart"
        Assets["Assets"]:::assets
        click Assets "https://github.com/okwama/woosh/tree/master/assets/"
        Icons["Web Icons"]:::assets
        click Icons "https://github.com/okwama/woosh/tree/master/web/icons/"
        subgraph "Platforms"
            direction TB
            Android["Android"]:::platform
            click Android "https://github.com/okwama/woosh/tree/master/android/"
            iOS["iOS"]:::platform
            click iOS "https://github.com/okwama/woosh/tree/master/ios/"
            Web["Web"]:::platform
            click Web "https://github.com/okwama/woosh/tree/master/web/"
            Windows["Windows"]:::platform
            click Windows "https://github.com/okwama/woosh/tree/master/windows/"
            macOS["macOS"]:::platform
            click macOS "https://github.com/okwama/woosh/tree/master/macos/"
            Linux["Linux"]:::platform
            click Linux "https://github.com/okwama/woosh/tree/master/linux/"
        end
    end

    %% API Server Layer
    subgraph "Node.js API" 
        direction TB
        APIControllers["Controllers"]:::backend
        click APIControllers "https://github.com/okwama/woosh/blob/master/api/controllers/analyticsController.js"
        APIRoot["Express App & Services"]:::backend
        click APIRoot "https://github.com/okwama/woosh/tree/master/api/"
    end

    %% Data Stores
    DB[(Database)]:::db
    Storage[(Object Storage)]:::cloud

    %% CI/CD Pipeline
    subgraph "CI/CD Pipeline"
        direction TB
        CM["Codemagic Config"]:::cicd
        click CM "https://github.com/okwama/woosh/blob/master/codemagic.yaml"
        Scripts["CI Scripts"]:::cicd
        click Scripts "https://github.com/okwama/woosh/blob/master/ci_scripts/post-clone.sh"
    end

    %% Data Flows
    Services -->|"1: REST Calls"| APIControllers
    APIControllers -->|"CRUD Operations"| DB
    Services -->|"File Uploads"| Storage
    CM -->|"Build & Deploy Client"| UI
    CM -->|"Build & Deploy API"| APIRoot

    %% Styles
    classDef frontend fill:#87CEFA,stroke:#333,stroke-width:1px
    classDef controllers fill:#ADD8E6,stroke:#333,stroke-width:1px
    classDef service fill:#00CED1,stroke:#333,stroke-width:1px
    classDef models fill:#DA70D6,stroke:#333,stroke-width:1px
    classDef utils fill:#D3D3D3,stroke:#333,stroke-width:1px
    classDef routes fill:#FFD700,stroke:#333,stroke-width:1px
    classDef assets fill:#FFB6C1,stroke:#333,stroke-width:1px
    classDef platform fill:#4682B4,stroke:#333,stroke-width:1px
    classDef backend fill:#32CD32,stroke:#333,stroke-width:1px
    classDef db fill:#FFA500,stroke:#333,stroke-width:1px
    classDef cloud fill:#FFA500,stroke-dasharray: 5 5,stroke:#333,stroke-width:1px
    classDef cicd fill:#FF6347,stroke:#333,stroke-width:1px