package org.keycloak.extensions.command;

import picocli.CommandLine;

@CommandLine.Command(name = "list", mixinStandardHelpOptions = true)
public class List implements Runnable {

    @Override
    public void run() {
        System.err.println("LIST");
        System.exit(0);
    }
}
