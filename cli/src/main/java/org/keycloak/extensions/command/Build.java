package org.keycloak.extensions.command;

import picocli.CommandLine;

@CommandLine.Command(name = "build", mixinStandardHelpOptions = true)
public class Build implements Runnable {

    @CommandLine.Option(names = "--keycloak-version")
    protected String keycloakVersion;

    @CommandLine.Option(names = "--quarkus-version")
    protected String quarkusVersion;

    @CommandLine.Option(names = "--container")
    protected Boolean isContainerMode;

    @Override
    public void run() {
        System.err.println("BUILD");
        System.err.println(keycloakVersion);
        System.err.println(quarkusVersion);
        System.err.println(isContainerMode);
        System.exit(0);
    }
}
