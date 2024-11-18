package org.keycloak.extensions.command;

import picocli.CommandLine;

@CommandLine.Command(name = "start-dev", mixinStandardHelpOptions = true)
public class StartDev implements Runnable {

    @Override
    public void run() {
        System.err.println("START DEV");
        System.exit(0);
    }
}
