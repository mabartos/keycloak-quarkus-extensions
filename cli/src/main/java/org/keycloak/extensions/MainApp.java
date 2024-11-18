package org.keycloak.extensions;

import io.quarkus.runtime.Quarkus;
import io.quarkus.runtime.QuarkusApplication;
import org.keycloak.extensions.command.Main;
import picocli.CommandLine;

public class MainApp implements QuarkusApplication {
    @Override
    public int run(String... args) {
        if (args.length == 0) {
            Quarkus.waitForExit();
            return -1;
        }

        return new CommandLine(Main.class).execute(args);
    }

    public static void main(String[] args) {
        Quarkus.run(MainApp.class, args);
        Quarkus.asyncExit();
    }
}
