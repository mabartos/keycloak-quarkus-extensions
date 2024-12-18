package org.keycloak.extensions.command;

import picocli.CommandLine;

@CommandLine.Command(name = "build", mixinStandardHelpOptions = true)
public class Build implements Runnable {

    @CommandLine.Option(names = "--keycloak-version")
    protected String keycloakVersion;

    @CommandLine.Option(names = "--quarkus-version")
    protected String quarkusVersion;

    @Override
    public void run() {
        System.err.println("BUILD");
        System.err.println(keycloakVersion);
        System.err.println(quarkusVersion);
        System.exit(0);
    }
}
