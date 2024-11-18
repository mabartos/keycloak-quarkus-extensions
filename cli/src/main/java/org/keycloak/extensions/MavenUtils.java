package org.keycloak.extensions;

import io.quarkus.logging.Log;
import io.quarkus.maven.dependency.GACTV;
import org.dom4j.Document;
import org.dom4j.Element;
import org.dom4j.io.OutputFormat;
import org.dom4j.io.SAXReader;
import org.dom4j.io.XMLWriter;

import java.io.File;
import java.io.FileWriter;
import java.nio.file.Path;

public class MavenUtils {

    public static Path getRelativePath(Path path) {
        return MavenInvoker.SCRIPT_DIR.relativize(path);
    }

    public static GACTV getGav(String groupId, String artifactId, String version) {
        return GACTV.fromString(groupId + ":" + artifactId + ":" + version);
    }

    public static void addDependencyToPom(File pom, GACTV gav) {
        try {
            SAXReader reader = new SAXReader();
            Document document = reader.read(pom);
            Element root = document.getRootElement();
            Element dependencies = root.element("dependencies");

            if (dependencies == null) {
                dependencies = root.addElement("dependencies");
            }

            var groupId = gav.getGroupId();
            var artifactId = gav.getArtifactId();
            var version = gav.getVersion();

            boolean exists = dependencies.elements("dependency").stream().anyMatch(dep -> {
                Element gid = dep.element("groupId");
                Element aid = dep.element("artifactId");
                return gid != null && gid.getText().equals(groupId) && aid != null && aid.getText().equals(artifactId);
            });

            var printablePath = MavenUtils.getRelativePath(pom.toPath());

            if (exists) {
                Log.infof("Dependency '%s' already exists in: %s", gav.toString(), printablePath);
                return;
            }

            Element dependency = dependencies.addElement("dependency");
            dependency.addElement("groupId").addText(groupId);
            dependency.addElement("artifactId").addText(artifactId);
            dependency.addElement("version").addText(version);

            OutputFormat format = OutputFormat.createPrettyPrint();
            format.setIndentSize(4);
            format.setSuppressDeclaration(true);
            format.setEncoding("UTF-8");

            XMLWriter writer = new XMLWriter(new FileWriter(pom), format);
            writer.write(document);
            writer.close();

            Log.infof("Dependency '%s' added to: %s", gav.toString(), printablePath);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
