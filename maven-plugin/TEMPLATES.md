# POM Templates

The Maven plugin uses template files instead of building POMs programmatically in code. This makes the plugin more maintainable and easier to customize.

## Template Files

Templates are located in `src/main/resources/templates/`:

### 1. build-project-template.xml

This template is used to create the temporary Maven project that builds the Keycloak distribution with custom extensions.

**Placeholders:**
- `@KEYCLOAK_VERSION@` - Replaced with the Keycloak version
- `@QUARKUS_VERSION@` - Replaced with the Quarkus version
- `@CUSTOM_DEPENDENCIES@` - Replaced with the XML for custom extension dependencies

**Example:**
```xml
<properties>
    <keycloak.version>@KEYCLOAK_VERSION@</keycloak.version>
    <quarkus.version>@QUARKUS_VERSION@</quarkus.version>
</properties>

<dependencies>
    <!-- Base Keycloak dependencies -->
    ...
@CUSTOM_DEPENDENCIES@
</dependencies>
```

### 2. unpack-distribution-template.xml

This template is used to create a temporary POM for unpacking the Keycloak distribution ZIP file.

**Placeholders:**
- `@KEYCLOAK_VERSION@` - Replaced with the Keycloak version to download
- `@OUTPUT_DIRECTORY@` - Replaced with the directory where the distribution should be unpacked

**Example:**
```xml
<artifactItem>
    <groupId>org.keycloak</groupId>
    <artifactId>keycloak-quarkus-dist</artifactId>
    <version>@KEYCLOAK_VERSION@</version>
    <type>zip</type>
    <outputDirectory>@OUTPUT_DIRECTORY@</outputDirectory>
</artifactItem>
```

## Customizing Templates

To customize the build process:

1. Locate the template file in `src/main/resources/templates/`
2. Edit the template (XML file)
3. Rebuild the plugin: `mvn clean install`

### Example: Adding a Repository

To add a custom Maven repository to the build project, edit `build-project-template.xml`:

```xml
</dependencies>

<repositories>
    <repository>
        <id>my-custom-repo</id>
        <url>https://my-repo.example.com/maven2</url>
    </repository>
</repositories>

<build>
```

### Example: Configuring Quarkus Plugin

To add custom Quarkus plugin configuration, edit `build-project-template.xml`:

```xml
<plugin>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-maven-plugin</artifactId>
    <version>${quarkus.version}</version>
    <configuration>
        <finalName>keycloak</finalName>
        <systemProperties>
            <kc.home.dir>${project.build.directory}/kc</kc.home.dir>
        </systemProperties>
    </configuration>
    <executions>
        <execution>
            <goals>
                <goal>build</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

## How Templates are Processed

The `BuildDistributionMojo` class processes templates as follows:

1. **Read template** - Uses `readTemplate(String templateName)` to load the template from resources
2. **Replace placeholders** - Uses `String.replace()` to substitute placeholder values
3. **Generate dependencies** - Uses `buildDependenciesXml()` to generate the custom dependencies section
4. **Write POM** - Writes the processed template to a file

### Code Example

```java
private void createBuildProject() throws IOException {
    String template = readTemplate("build-project-template.xml");
    String pomContent = template
        .replace("@KEYCLOAK_VERSION@", keycloakVersion)
        .replace("@QUARKUS_VERSION@", quarkusVersion)
        .replace("@CUSTOM_DEPENDENCIES@", buildDependenciesXml());

    File buildPom = new File(buildDirectory, "pom.xml");
    try (FileWriter writer = new FileWriter(buildPom)) {
        writer.write(pomContent);
    }
}
```

## Benefits of Template-Based Approach

1. **Maintainability** - XML templates are easier to read and modify than Java string concatenation
2. **Separation of Concerns** - Build configuration is separate from plugin logic
3. **Validation** - Templates can be validated as XML in IDEs
4. **Extensibility** - Easy to add new features without touching Java code
5. **Version Control** - Changes to templates are clearer in diffs

## Debugging Templates

To debug template processing:

1. Enable Maven debug logging: `mvn -X package`
2. Check generated POMs in `target/keycloak-build/pom.xml` and `target/temp-unpack-pom.xml`
3. Verify template files are included in the JAR: `jar tf target/keycloak-distribution-maven-plugin-*.jar | grep templates`

## Adding New Templates

To add a new template:

1. Create the template file in `src/main/resources/templates/`
2. Add placeholders using `@PLACEHOLDER_NAME@` convention
3. Add a method in `BuildDistributionMojo` to process the template
4. Use `readTemplate("your-template.xml")` to load it
5. Replace placeholders with actual values
6. Rebuild and test the plugin

## Template Naming Convention

- Use kebab-case for template file names
- Suffix with `-template.xml`
- Be descriptive: `build-project-template.xml`, `unpack-distribution-template.xml`

## Reserved Placeholders

The following placeholder patterns are currently used:

- `@KEYCLOAK_VERSION@` - Keycloak version
- `@QUARKUS_VERSION@` - Quarkus version
- `@CUSTOM_DEPENDENCIES@` - Generated dependencies XML
- `@OUTPUT_DIRECTORY@` - Output directory path

Avoid using these names for new placeholders to prevent conflicts.
