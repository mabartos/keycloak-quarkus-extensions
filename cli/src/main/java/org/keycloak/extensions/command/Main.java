package org.keycloak.extensions.command;

import io.quarkus.picocli.runtime.annotations.TopCommand;
import org.keycloak.extensions.command.Add;
import org.keycloak.extensions.command.Build;
import org.keycloak.extensions.command.List;
import org.keycloak.extensions.command.StartDev;
import picocli.CommandLine;

@TopCommand
@CommandLine.Command(name = "keycloak-extended",
        header = {
                "Keycloak Quarkus Extensions - Add Quarkus/Quarkiverse extensions to your Keycloak deployment",
        },
        description = {
                "%nUse this command-line tool to extend your Keycloak deployment."
        },
        mixinStandardHelpOptions = true,
        subcommands = {
                Add.class,
                Build.class,
                List.class,
                StartDev.class
        })
public class Main implements Runnable {

    @CommandLine.Spec
    CommandLine.Model.CommandSpec spec;

    @Override
    public void run() {
        CommandLine.usage(this, System.out);
    }
}
