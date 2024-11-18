package org.keycloak.extensions;

import org.apache.maven.shared.invoker.DefaultInvocationRequest;
import org.apache.maven.shared.invoker.DefaultInvoker;
import org.apache.maven.shared.invoker.InvocationRequest;
import org.apache.maven.shared.invoker.Invoker;
import org.apache.maven.shared.invoker.MavenInvocationException;

import java.io.File;
import java.nio.file.Path;
import java.util.List;

public class MavenInvoker {

    public static final Path SCRIPT_DIR = Path.of(System.getProperty("user.dir"));
    public static final File RUNTIME_POM = new File(SCRIPT_DIR + "/runtime/pom.xml");
    public static final File DEPLOYMENT_POM = new File(SCRIPT_DIR + "/deployment/pom.xml");
    private static final File MVN_WRAPPER = new File(SCRIPT_DIR + "/mvnw");

    public static void invoke(File pom, String... args) {
        invoke(pom, List.of(args));
    }

    public static void invoke(File pom, List<String> args) {
        InvocationRequest request = new DefaultInvocationRequest();
        request.addArgs(args);
        request.setPomFile(pom);

        Invoker invoker = new DefaultInvoker();
        invoker.setMavenExecutable(MVN_WRAPPER);
        try {
            invoker.execute(request);
        } catch (MavenInvocationException e) {
            throw new RuntimeException(e);
        }
    }
}
