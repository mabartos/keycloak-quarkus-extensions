package org.keycloak.maven;

import org.apache.maven.artifact.Artifact;
import org.apache.maven.execution.MavenSession;
import org.apache.maven.model.Dependency;
import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugins.annotations.Component;
import org.apache.maven.plugins.annotations.LifecyclePhase;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;
import org.apache.maven.plugins.annotations.ResolutionScope;
import org.apache.maven.project.MavenProject;
import org.apache.maven.shared.invoker.DefaultInvocationRequest;
import org.apache.maven.shared.invoker.DefaultInvoker;
import org.apache.maven.shared.invoker.InvocationRequest;
import org.apache.maven.shared.invoker.Invoker;
import org.apache.maven.shared.invoker.MavenInvocationException;
import org.codehaus.plexus.archiver.UnArchiver;
import org.codehaus.plexus.archiver.manager.ArchiverManager;
import org.codehaus.plexus.archiver.manager.NoSuchArchiverException;
import org.codehaus.plexus.util.FileUtils;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Properties;
import java.util.Scanner;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Maven plugin to build an enhanced Keycloak distribution with custom extensions.
 */
@Mojo(
    name = "build",
    defaultPhase = LifecyclePhase.PACKAGE,
    requiresDependencyResolution = ResolutionScope.COMPILE_PLUS_RUNTIME
)
public class BuildDistributionMojo extends AbstractMojo {

    /**
     * The Maven project.
     */
    @Parameter(defaultValue = "${project}", readonly = true, required = true)
    private MavenProject project;

    /**
     * The current Maven session.
     */
    @Parameter(defaultValue = "${session}", readonly = true, required = true)
    private MavenSession session;

    /**
     * The Keycloak version to use for the base distribution.
     */
    @Parameter(property = "keycloak.version", required = true)
    private String keycloakVersion;

    /**
     * The Quarkus version to use (must be aligned with Keycloak version).
     * If not specified, it will be automatically detected from the Keycloak parent pom.xml on GitHub.
     */
    @Parameter(property = "quarkus.version", required = false)
    private String quarkusVersion;

    /**
     * List of additional dependencies (extensions) to include in the distribution.
     * Each dependency should specify groupId, artifactId, and version.
     */
    @Parameter(property = "extensions")
    private List<Dependency> extensions;

    /**
     * The output directory for the distribution.
     */
    @Parameter(defaultValue = "${project.build.directory}", readonly = true)
    private File outputDirectory;

    /**
     * The name of the final distribution.
     */
    @Parameter(property = "distribution.finalName", defaultValue = "keycloak-extended-${keycloak.version}")
    private String finalName;

    /**
     * Skip the plugin execution.
     */
    @Parameter(property = "keycloak.dist.skip", defaultValue = "false")
    private boolean skip;

    /**
     * Directory where the Keycloak distribution will be unpacked.
     */
    @Parameter(defaultValue = "${project.build.directory}/unpacked")
    private File unpackDirectory;

    /**
     * Directory for the working build.
     */
    @Parameter(defaultValue = "${project.build.directory}/keycloak-build")
    private File buildDirectory;

    @Component
    private ArchiverManager archiverManager;

    @Override
    public void execute() throws MojoExecutionException, MojoFailureException {
        if (skip) {
            getLog().info("Skipping Keycloak distribution build");
            return;
        }

        getLog().info("Building Keycloak distribution with version: " + keycloakVersion);

        // Auto-detect Quarkus version if not specified
        if (quarkusVersion == null || quarkusVersion.trim().isEmpty()) {
            getLog().info("Quarkus version not specified, auto-detecting from Keycloak parent pom.xml on GitHub...");
            try {
                quarkusVersion = fetchQuarkusVersionFromGitHub(keycloakVersion);
                getLog().info("Auto-detected Quarkus version: " + quarkusVersion);
            } catch (Exception e) {
                throw new MojoExecutionException(
                    "Failed to auto-detect Quarkus version from GitHub. " +
                    "Please specify quarkusVersion explicitly in plugin configuration.", e);
            }
        } else {
            getLog().info("Using Quarkus version: " + quarkusVersion);
        }

        try {
            // Create necessary directories
            createDirectories();

            // Download and unpack base Keycloak distribution
            downloadAndUnpackKeycloakDistribution();

            // Create a temporary Maven project for building
            createBuildProject();

            // Build the distribution with Quarkus
            buildWithQuarkus();

            // Package the distribution
            packageDistribution();

            getLog().info("Successfully built Keycloak distribution: " + finalName);

        } catch (Exception e) {
            throw new MojoExecutionException("Failed to build Keycloak distribution", e);
        }
    }

    /**
     * Reads a template file from the resources directory.
     */
    private String readTemplate(String templateName) throws IOException {
        String templatePath = "/templates/" + templateName;
        try (InputStream is = getClass().getResourceAsStream(templatePath)) {
            if (is == null) {
                throw new IOException("Template not found: " + templatePath);
            }
            try (Scanner scanner = new Scanner(is, StandardCharsets.UTF_8.name())) {
                scanner.useDelimiter("\\A");
                return scanner.hasNext() ? scanner.next() : "";
            }
        }
    }

    /**
     * Builds the custom dependencies XML section for the POM template.
     */
    private String buildDependenciesXml() {
        if (extensions == null || extensions.isEmpty()) {
            return "";
        }

        StringBuilder deps = new StringBuilder();
        for (Dependency dep : extensions) {
            deps.append("        <dependency>\n");
            deps.append("            <groupId>").append(dep.getGroupId()).append("</groupId>\n");
            deps.append("            <artifactId>").append(dep.getArtifactId()).append("</artifactId>\n");
            deps.append("            <version>").append(dep.getVersion()).append("</version>\n");
            if (dep.getScope() != null) {
                deps.append("            <scope>").append(dep.getScope()).append("</scope>\n");
            }
            if (dep.getType() != null && !dep.getType().equals("jar")) {
                deps.append("            <type>").append(dep.getType()).append("</type>\n");
            }
            deps.append("        </dependency>\n");
        }
        return deps.toString();
    }

    /**
     * Fetches the Quarkus version from Keycloak's parent pom.xml on GitHub.
     */
    private String fetchQuarkusVersionFromGitHub(String keycloakVersion) throws IOException, InterruptedException {
        String githubUrl = buildGitHubPomUrl(keycloakVersion);
        getLog().debug("Fetching Keycloak pom.xml from: " + githubUrl);

        HttpClient client = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create(githubUrl))
            .GET()
            .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            throw new IOException("Failed to fetch Keycloak pom.xml from GitHub. HTTP " +
                response.statusCode() + ": " + githubUrl);
        }

        String pomContent = response.body();
        return parseQuarkusVersion(pomContent);
    }

    /**
     * Builds the GitHub URL for the Keycloak parent pom.xml based on the version.
     */
    private String buildGitHubPomUrl(String version) {
        // For SNAPSHOT or main versions, use the main branch
        if (version.contains("SNAPSHOT") || version.equals("main")) {
            return "https://raw.githubusercontent.com/keycloak/keycloak/refs/heads/main/pom.xml";
        }

        // For release versions, use the tag
        return "https://raw.githubusercontent.com/keycloak/keycloak/refs/tags/" + version + "/pom.xml";
    }

    /**
     * Parses the quarkus.version property from the pom.xml content.
     */
    private String parseQuarkusVersion(String pomContent) throws IOException {
        // Look for <quarkus.version>X.Y.Z</quarkus.version>
        Pattern pattern = Pattern.compile("<quarkus\\.version>([^<]+)</quarkus\\.version>");
        Matcher matcher = pattern.matcher(pomContent);

        if (matcher.find()) {
            return matcher.group(1);
        }

        throw new IOException("Could not find quarkus.version in Keycloak pom.xml");
    }

    private void createDirectories() throws IOException {
        if (!outputDirectory.exists()) {
            outputDirectory.mkdirs();
        }
        if (!unpackDirectory.exists()) {
            unpackDirectory.mkdirs();
        }
        if (!buildDirectory.exists()) {
            buildDirectory.mkdirs();
        }
    }

    private void downloadAndUnpackKeycloakDistribution() throws MojoExecutionException {
        getLog().info("Downloading and unpacking Keycloak distribution...");

        // The Keycloak distribution artifact
        String groupId = "org.keycloak";
        String artifactId = "keycloak-quarkus-dist";
        String type = "zip";

        // Create artifact coordinates
        File distributionFile = new File(outputDirectory, "keycloak-" + keycloakVersion + ".zip");

        // Use Maven to resolve and download the artifact
        try {
            // Create a temporary POM to download the artifact
            File tempPom = new File(outputDirectory, "temp-download-pom.xml");
            createDownloadPom(tempPom, groupId, artifactId, keycloakVersion, type);

            // Use Maven invoker to download the artifact
            InvocationRequest request = new DefaultInvocationRequest();
            request.setPomFile(tempPom);
            request.setGoals(Arrays.asList("dependency:copy-dependencies"));
            request.setBatchMode(true);

            Properties props = new Properties();
            props.setProperty("outputDirectory", outputDirectory.getAbsolutePath());
            props.setProperty("includeArtifactIds", artifactId);
            request.setProperties(props);

            Invoker invoker = new DefaultInvoker();
            invoker.execute(request);

            // Find the downloaded file
            File[] files = outputDirectory.listFiles((dir, name) ->
                name.startsWith("keycloak-quarkus-dist") && name.endsWith(".zip"));

            if (files == null || files.length == 0) {
                // Try alternative: use dependency plugin to unpack directly
                getLog().info("Using dependency:unpack to get Keycloak distribution");
                unpackKeycloakDirectly(groupId, artifactId, keycloakVersion, type);
            } else {
                // Unpack the distribution
                unpackArchive(files[0], unpackDirectory);
            }

            // Clean up temp POM
            if (tempPom.exists()) {
                tempPom.delete();
            }

        } catch (Exception e) {
            throw new MojoExecutionException("Failed to download Keycloak distribution", e);
        }
    }

    private void unpackKeycloakDirectly(String groupId, String artifactId, String version, String type)
            throws MojoExecutionException {
        try {
            File tempPom = new File(outputDirectory, "temp-unpack-pom.xml");
            createUnpackPom(tempPom, groupId, artifactId, version, type);

            InvocationRequest request = new DefaultInvocationRequest();
            request.setPomFile(tempPom);
            request.setGoals(Arrays.asList("dependency:unpack"));
            request.setBatchMode(true);

            Invoker invoker = new DefaultInvoker();
            invoker.execute(request);

            if (tempPom.exists()) {
                tempPom.delete();
            }
        } catch (IOException | MavenInvocationException e) {
            throw new MojoExecutionException("Failed to unpack Keycloak distribution", e);
        }
    }

    private void createDownloadPom(File pomFile, String groupId, String artifactId, String version, String type)
            throws IOException {
        String pomContent = String.format(
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
            "<project xmlns=\"http://maven.apache.org/POM/4.0.0\"\n" +
            "         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n" +
            "         xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd\">\n" +
            "    <modelVersion>4.0.0</modelVersion>\n" +
            "    <groupId>temp</groupId>\n" +
            "    <artifactId>temp</artifactId>\n" +
            "    <version>1.0</version>\n" +
            "    <dependencies>\n" +
            "        <dependency>\n" +
            "            <groupId>%s</groupId>\n" +
            "            <artifactId>%s</artifactId>\n" +
            "            <version>%s</version>\n" +
            "            <type>%s</type>\n" +
            "        </dependency>\n" +
            "    </dependencies>\n" +
            "</project>",
            groupId, artifactId, version, type
        );

        try (FileWriter writer = new FileWriter(pomFile)) {
            writer.write(pomContent);
        }
    }

    private void createUnpackPom(File pomFile, String groupId, String artifactId, String version, String type)
            throws IOException {
        String template = readTemplate("unpack-distribution-template.xml");
        String pomContent = template
            .replace("@KEYCLOAK_VERSION@", version)
            .replace("@OUTPUT_DIRECTORY@", unpackDirectory.getAbsolutePath());

        try (FileWriter writer = new FileWriter(pomFile)) {
            writer.write(pomContent);
        }
    }

    private void unpackArchive(File archive, File destination) throws MojoExecutionException {
        try {
            UnArchiver unArchiver = archiverManager.getUnArchiver(archive);
            unArchiver.setSourceFile(archive);
            unArchiver.setDestDirectory(destination);
            unArchiver.extract();
            getLog().info("Unpacked Keycloak distribution to: " + destination);
        } catch (NoSuchArchiverException e) {
            throw new MojoExecutionException("No unarchiver found for: " + archive, e);
        }
    }

    private void createBuildProject() throws IOException {
        getLog().info("Creating build project with extensions...");

        if (extensions != null && !extensions.isEmpty()) {
            getLog().info("Adding " + extensions.size() + " custom extension(s)");
        }

        // Read template and replace placeholders
        String template = readTemplate("build-project-template.xml");
        String pomContent = template
            .replace("@KEYCLOAK_VERSION@", keycloakVersion)
            .replace("@QUARKUS_VERSION@", quarkusVersion)
            .replace("@CUSTOM_DEPENDENCIES@", buildDependenciesXml());

        File buildPom = new File(buildDirectory, "pom.xml");
        try (FileWriter writer = new FileWriter(buildPom)) {
            writer.write(pomContent);
        }

        getLog().info("Created build POM at: " + buildPom.getAbsolutePath());
    }

    private void buildWithQuarkus() throws MojoExecutionException {
        getLog().info("Building distribution with Quarkus...");

        try {
            InvocationRequest request = new DefaultInvocationRequest();
            request.setPomFile(new File(buildDirectory, "pom.xml"));
            request.setGoals(Arrays.asList("clean", "package"));
            request.setBatchMode(true);

            Properties props = new Properties();
            props.setProperty("skipTests", "true");
            request.setProperties(props);

            Invoker invoker = new DefaultInvoker();
            invoker.execute(request);

            getLog().info("Quarkus build completed successfully");

        } catch (MavenInvocationException e) {
            throw new MojoExecutionException("Failed to build with Quarkus", e);
        }
    }

    private void packageDistribution() throws MojoExecutionException, IOException {
        getLog().info("Packaging distribution...");

        // Find the unpacked Keycloak directory
        File[] keycloakDirs = unpackDirectory.listFiles(File::isDirectory);
        if (keycloakDirs == null || keycloakDirs.length == 0) {
            throw new MojoExecutionException("Could not find unpacked Keycloak directory");
        }

        File keycloakDir = keycloakDirs[0];
        File distributionDir = new File(outputDirectory, finalName);

        // Copy the base Keycloak distribution
        FileUtils.copyDirectoryStructure(keycloakDir, distributionDir);

        // Copy the built libraries from Quarkus build
        File quarkusLibDir = new File(buildDirectory, "target/lib");
        if (quarkusLibDir.exists()) {
            File targetLibDir = new File(distributionDir, "lib");
            FileUtils.copyDirectoryStructure(quarkusLibDir, targetLibDir);
        }

        getLog().info("Distribution packaged at: " + distributionDir.getAbsolutePath());

        // Create zip and tar.gz archives
        createArchives(distributionDir);
    }

    private void createArchives(File distributionDir) throws MojoExecutionException {
        getLog().info("Creating distribution archives...");

        // For simplicity, we'll use Maven Assembly plugin approach
        // You could also use Plexus archivers directly here

        getLog().info("Distribution directory ready at: " + distributionDir.getAbsolutePath());
        getLog().info("You can manually create archives or extend this plugin to use Assembly plugin");
    }
}
