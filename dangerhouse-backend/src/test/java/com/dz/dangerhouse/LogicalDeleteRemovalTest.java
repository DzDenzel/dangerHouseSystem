package com.dz.dangerhouse;

import com.dz.dangerhouse.cache.AuthUserCacheEntry;
import com.dz.dangerhouse.entity.Building;
import com.dz.dangerhouse.entity.Detection;
import com.dz.dangerhouse.entity.Image;
import com.dz.dangerhouse.entity.Report;
import com.dz.dangerhouse.entity.User;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertFalse;

class LogicalDeleteRemovalTest {

    @Test
    void entitiesAndAuthCacheDoNotExposeDeletedField() {
        List.of(User.class, Building.class, Detection.class, Image.class, Report.class, AuthUserCacheEntry.class)
                .forEach(type -> assertFalse(
                        List.of(type.getDeclaredFields()).stream()
                                .anyMatch(field -> field.getName().equals("deleted")),
                        type.getSimpleName() + " must not expose deleted field"
                ));
    }

    @Test
    void configurationAndFinalSqlDoNotContainLogicalDeleteField() throws IOException {
        assertDoesNotContain(Path.of("src/main/resources/application.yml"), "logic-delete");
        assertDoesNotContain(Path.of("sql/dangerhouse_v3.0.sql"), "`deleted`");
        assertDoesNotContain(Path.of("sql/dangerhouse_v3.0_with_data.sql"), "`deleted`");
        assertDoesNotContain(Path.of("sql/dangerhouse_v3.0.sql"), "idx_deleted");
        assertDoesNotContain(Path.of("sql/dangerhouse_v3.0_with_data.sql"), "idx_deleted");
        assertDoesNotContain(Path.of("src/main/java/com/dz/dangerhouse/DangerhouseApplication.java"), "@EnableScheduling");
        assertFalse(Files.exists(Path.of(
                "src/main/java/com/dz/dangerhouse/scheduler/DataCleanupScheduler.java"
        )));
    }

    private void assertDoesNotContain(Path path, String forbiddenText) throws IOException {
        assertFalse(Files.readString(path).contains(forbiddenText),
                path + " must not contain " + forbiddenText);
    }
}
