package org.keycloak.extensions.command;

import org.keycloak.extensions.MavenInvoker;
import picocli.CommandLine;

@CommandLine.Command(name = "list", mixinStandardHelpOptions = true)
public class List implements Runnable {

    @Override
    public void run() {
        MavenInvoker.invoke(MavenInvoker.RUNTIME_POM, "quarkus:list-extensions");
        System.exit(0);
    }
}
