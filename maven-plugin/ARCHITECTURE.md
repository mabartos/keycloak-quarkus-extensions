# Maven Plugin Architecture

## Overview

The Keycloak Distribution Maven Plugin now follows the same modular architecture as the main project's `resolver` module, ensuring consistency and leveraging the project's existing single-source-of-truth approach.

## Architecture Comparison

### Old Approach (Deprecated)
The plugin created a single standalone temporary POM with all dependencies:
```
target/keycloak-build/
└── pom.xml  (monolithic, all-in-one)
```

### New Approach (Current)
The plugin creates a multi-module Maven project structure identical to the main project:
```
target/keycloak-build/
├── pom.xml (parent)
├── runtime/
│   └── pom.xml (runtime extensions)
├── deployment/
│   └── pom.xml (deployment extensions)
└── resolver/
    ├── pom.xml (build orchestration)
    └── assembly.xml (distribution packaging)
```

## Module Responsibilities

### Parent Module
- Defines common properties (`keycloak.version`, `quarkus.version`)
- Manages dependency versions via `quarkus-bom`
- Coordinates the build order of child modules

### Runtime Module
- Contains runtime Quarkus extensions
- Depends on `keycloak-quarkus-server`
- User's extensions are injected here
- Uses `quarkus-extension-maven-plugin` to generate extension descriptor

### Deployment Module
- Contains deployment-time Quarkus extensions
- Depends on `keycloak-quarkus-server-deployment`
- Depends on runtime module
- Deployment variants of user's extensions (with `-deployment` suffix) are injected here
- Required for Quarkus build-time processing

### Resolver Module
- Orchestrates the final distribution build
- Depends on both runtime and deployment modules
- Unpacks base Keycloak distribution via `maven-dependency-plugin`
- Runs `quarkus-maven-plugin` to build with extensions
- Uses `maven-assembly-plugin` to package final distribution (zip/tar.gz)

## Build Flow

1. **Module Generation**
   ```
   Plugin reads templates from resources/templates/
   ├── parent-module-template.xml
   ├── runtime-module-template.xml
   ├── deployment-module-template.xml
   ├── resolver-module-template.xml
   └── assembly.xml
   ```

2. **Dependency Injection**
   ```
   User's extensions from plugin configuration:
   <dependency>
       <groupId>io.quarkus</groupId>
       <artifactId>quarkus-mongodb-client</artifactId>
       <version>3.27.0</version>
   </dependency>

   Runtime module gets:      deployment module gets:
   └── quarkus-mongodb-client    └── quarkus-mongodb-client-deployment
   ```

3. **Maven Build Process**
   ```
   mvn clean install
   ├── 1. Build runtime module (compiles extension descriptor)
   ├── 2. Build deployment module (compile-time processing)
   └── 3. Build resolver module
       ├── a. Unpack Keycloak distribution
       ├── b. Run Quarkus build with extensions
       └── c. Assemble final distribution (zip + tar.gz)
   ```

4. **Output**
   ```
   target/keycloak-build/resolver/target/
   ├── keycloak-extended-26.4.1.zip
   └── keycloak-extended-26.4.1.tar.gz
   ```

## Benefits of Module-Based Approach

### 1. **Single Source of Truth**
- Uses the same architecture as `resolver/` module in main project
- Changes to main project's build process automatically align with plugin
- Reduces maintenance burden

### 2. **Proper Quarkus Extension Handling**
- Correctly separates runtime and deployment concerns
- Follows Quarkus extension best practices
- Enables build-time optimizations

### 3. **Better Dependency Management**
- Leverages Maven's multi-module dependency resolution
- Proper scope handling (runtime vs provided)
- Avoids classpath conflicts

### 4. **Debugging and Transparency**
- Generated modules can be inspected in `target/keycloak-build/`
- Each module can be built independently for troubleshooting
- Clear separation of concerns

### 5. **Extensibility**
- Easy to add more modules if needed
- Can customize individual module behaviors
- Supports advanced Maven features (profiles, properties, etc.)

## Template System

### Placeholders

Templates use placeholder substitution:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `@KEYCLOAK_VERSION@` | Keycloak version | `26.4.1` |
| `@QUARKUS_VERSION@` | Quarkus version | `3.27.0` |
| `@FINAL_NAME@` | Distribution name | `keycloak-extended-26.4.1` |
| `@RUNTIME_DEPENDENCIES@` | Runtime extensions XML | `<dependency>...</dependency>` |
| `@DEPLOYMENT_DEPENDENCIES@` | Deployment extensions XML | `<dependency>...</dependency>` |

### Template Processing

```java
// Example: Generate runtime module
String template = readTemplate("runtime-module-template.xml");
String pomContent = template
    .replace("@KEYCLOAK_VERSION@", keycloakVersion)
    .replace("@QUARKUS_VERSION@", quarkusVersion)
    .replace("@RUNTIME_DEPENDENCIES@", buildRuntimeDependenciesXml());
writeFile(new File(runtimeDir, "pom.xml"), pomContent);
```

## Alignment with Main Project

The plugin's approach mirrors the main project's workflow:

### Main Project (scripts/command-add.sh)
```bash
1. Add dependency to runtime/pom.xml using sed
2. Add -deployment variant to deployment/pom.xml
3. Run mvn clean install
4. resolver/ module builds distribution
```

### Maven Plugin
```java
1. Generate runtime/pom.xml with dependencies from plugin config
2. Generate deployment/pom.xml with -deployment variants
3. Invoke Maven on generated parent project
4. resolver/ module builds distribution
```

## Comparison to Alternatives

### Why not a single POM?
- Doesn't support proper Quarkus extension descriptor generation
- Can't separate runtime/deployment concerns
- Loses Quarkus build-time optimizations

### Why not use the existing resolver/ directly?
- Plugin needs to be standalone and not modify source files
- Users might not have the full project structure
- Provides isolation for different configurations

### Why not use Maven Invoker Plugin?
- Module-based approach gives better control
- Allows for future customizations per module
- More transparent for debugging

## Future Enhancements

Potential improvements building on this architecture:

1. **Module Caching**: Cache unchanged modules between builds
2. **Incremental Builds**: Only rebuild changed modules
3. **Custom Modules**: Allow users to provide additional modules
4. **Profile Support**: Enable different configurations per environment
5. **Source Generation**: Generate Java sources in modules if needed

## Troubleshooting

### Inspecting Generated Modules

```bash
# View generated parent POM
cat target/keycloak-build/pom.xml

# View runtime dependencies
cat target/keycloak-build/runtime/pom.xml

# View deployment dependencies
cat target/keycloak-build/deployment/pom.xml

# View resolver configuration
cat target/keycloak-build/resolver/pom.xml

# Build manually for debugging
cd target/keycloak-build
mvn clean install -X
```

### Common Issues

**Issue**: Module not found during build
**Solution**: Check that all modules are listed in parent's `<modules>` section

**Issue**: Quarkus extension not detected
**Solution**: Verify extension is in runtime/ and -deployment variant in deployment/

**Issue**: Distribution packaging fails
**Solution**: Check assembly.xml is properly copied to resolver/ directory

## References

- Main project resolver module: `/resolver/pom.xml`
- Build script: `/scripts/command-build.sh`
- Add extension script: `/scripts/command-add.sh`
- Quarkus Extension Guide: https://quarkus.io/guides/writing-extensions
