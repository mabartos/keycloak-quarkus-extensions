package org.keycloak.extensions.command;

import io.quarkus.logging.Log;
import io.quarkus.maven.dependency.GACTV;
import org.keycloak.extensions.MavenInvoker;
import org.keycloak.extensions.MavenUtils;
import picocli.CommandLine;

import static org.keycloak.extensions.MavenInvoker.DEPLOYMENT_POM;
import static org.keycloak.extensions.MavenInvoker.RUNTIME_POM;

@CommandLine.Command(name = "add", mixinStandardHelpOptions = true)
public class Add implements Runnable {

    @CommandLine.Parameters(index = "0", description = "Extension name or GAV (groupId:artifactId:version).")
    private String input;

    @Override
    public void run() {
        if (input.contains(":")) {
            try {
                var artifact = GACTV.fromString(input);
                handleAddGav(artifact);
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("You need to provide valid GAV - groupId:artifactId:version", e);
            }
        } else {
            handleAddExtensionName(input);
        }
        System.exit(0);
    }

    protected void handleAddGav(GACTV gactv) {
        Log.info("Adding extension by GAV");

        MavenUtils.addDependencyToPom(RUNTIME_POM, gactv);
        var gavDeployment = MavenUtils.getGav(gactv.getGroupId(), gactv.getArtifactId() + "-deployment", gactv.getVersion());
        MavenUtils.addDependencyToPom(DEPLOYMENT_POM, gavDeployment);
    }

    protected void handleAddExtensionName(String extensionName) {
        Log.info("Adding extension by name: " + extensionName);
        MavenInvoker.invoke(RUNTIME_POM, "quarkus:add-extension", "-Dextension=" + extensionName);
    }
}
