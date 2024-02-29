#!/bin/bash

# set default options

defaultArtifactId=spring_crud_app
defaultGroupId=ru.mondayish
defaultSpringBootVersion=2.4.2
defaultJavaVersion=8
defaultEntityDirectory=entities
defaultGenerationType=IDENTITY

# set options from file
source data.properties
if [[ -z "$artifactId" ]]
	then artifactId=$defaultArtifactId
fi
if [[ -z "$groupId" ]]
        then groupId=$defaultGroupId
fi
if [[ -z "$springBootVersion" ]]
        then springBootVersion=$defaultSpringBootVersion
fi
if [[ -z "$javaVersion" ]]
        then javaVersion=$defaultJavaVersion
fi
if [[ -z "$entityDirectory" ]]
	then entityDirectory=$defaultEntityDirectory
fi
if [[ -z "$generationType" ]]
        then generationType=$defaultGenerationType
fi


entities=$(ls $entityDirectory)
package=${groupId//\./\/}

# generating maven project

mvn archetype:generate -DgroupId=$groupId -DartifactId=$artifactId -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.4 -DinteractiveMode=false

cd $artifactId

echo '<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>'$springBootVersion'</version>
    </parent>

    <groupId>'$groupId'</groupId>
    <artifactId>'$artifactId'</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <java.version>'$javaVersion'</java.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>' > pom.xml

rm -rf src/main/java/$package/*

# main app class
echo 'package '$groupId';

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}' > src/main/java/$package/Application.java

cd src/main/java/$package/
mkdir controllers repositories services models
cd - 1>/dev/null
cd ..

# clear test directory
rm -rf $artifactId/src/test/java/*

# set default application properties for postgres database
mkdir $artifactId/src/main/resources
echo '
spring.datasource.url=jdbc:postgresql://localhost:5432/postgres
spring.datasource.username=root
spring.datasource.password=root
spring.jpa.hibernate.ddl-auto=update
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
' > $artifactId/src/main/resources/application.properties


# common rest service

echo 'package '$groupId'.services;

import java.util.List;
import java.util.Optional;

public interface CommonService<T>{

    T create(T t);

    Optional<T> get(Long id);

    List<T> getAll();

    boolean update(T t);

    void delete(Long id);
}' > $artifactId/src/main/java/$package/services/CommonService.java

for entity in $entities; do
	lowerEntity=${entity,}
	upperEntity=${entity^}

	# entity class
	echo 'package '$groupId'.models;

	     import lombok.Getter;
         import lombok.NoArgsConstructor;
         import lombok.Setter;
	     import javax.persistence.*;

         @Entity
	     @NoArgsConstructor
         @Getter
         @Setter
         @Table
	     public class '$upperEntity' {

	     @Id
    	 @GeneratedValue(strategy = GenerationType.'$generationType')
    	 private long id;
	     ' > $artifactId/src/main/java/$package/models/$upperEntity.java
	cat $entityDirectory/$entity | while read line; do
		echo 'private '$line';' >> $artifactId/src/main/java/$package/models/$upperEntity.java
	done
	echo '}' >> $artifactId/src/main/java/$package/models/$upperEntity.java

	# repository interface
	echo 'package '$groupId'.repositories;

	import org.springframework.data.jpa.repository.JpaRepository;
	import '$groupId'.models.'$upperEntity';

	public interface '$upperEntity'Repository extends JpaRepository<'$upperEntity', Long> {
	}' > $artifactId/src/main/java/$package/repositories/"$upperEntity"Repository.java

	# entity service
	echo 'package '$groupId'.services;

import org.springframework.stereotype.Service;
import '$groupId'.models.'$upperEntity';
import '$groupId'.repositories.'$upperEntity'Repository;

import java.util.List;
import java.util.Optional;

@Service
public class '$upperEntity'Service implements CommonService<'$upperEntity'> {

    private final '$upperEntity'Repository '$lowerEntity'Repository;

    public '$upperEntity'Service('$upperEntity'Repository '$lowerEntity'Repository) {
        this.'$lowerEntity'Repository = '$lowerEntity'Repository;
    }

    @Override
    public '$upperEntity' create('$upperEntity' '$lowerEntity') {
        return '$lowerEntity'Repository.save('$lowerEntity');
    }

    @Override
    public Optional<'$upperEntity'> get(Long id) {
        return '$lowerEntity'Repository.findById(id);
    }

    @Override
    public List<'$upperEntity'> getAll() {
        return '$lowerEntity'Repository.findAll();
    }

    @Override
    public boolean update('$upperEntity' '$lowerEntity') {
        if ('$lowerEntity'Repository.existsById('$lowerEntity'.getId())) {
            '$lowerEntity'Repository.save('$lowerEntity');
            return true;
        }
        return false;
    }

    @Override
    public void delete(Long id) {
        '$lowerEntity'Repository.deleteById(id);
    }
	}' > $artifactId/src/main/java/$package/services/"$upperEntity"Service.java

	# controller
	echo 'package '$groupId'.controllers;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import '$groupId'.models.'$upperEntity';
import '$groupId'.services.CommonService;

import java.util.Optional;
import java.util.List;

@RestController
@RequestMapping("/api/'$lowerEntity'")
public class '$upperEntity'Controller {

    private final CommonService<'$upperEntity'> '$lowerEntity'Service;

    public '$upperEntity'Controller(CommonService<'$upperEntity'> '$lowerEntity'Service) {
        this.'$lowerEntity'Service = '$lowerEntity'Service;
    }

    @GetMapping
    public List<'$upperEntity'> getAll'$upperEntity's() {
        return '$lowerEntity'Service.getAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<'$upperEntity'> get'$upperEntity'ById(@PathVariable Long id) {
        Optional<'$upperEntity'> opt = '$lowerEntity'Service.get(id);
        return opt.map('$lowerEntity' -> new ResponseEntity<>('$lowerEntity', HttpStatus.OK)).orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
    }

    @PostMapping
    public ResponseEntity<'$upperEntity'> create'$upperEntity'(@RequestBody '$upperEntity' '$lowerEntity') {
        '$upperEntity' created'$upperEntity' = '$lowerEntity'Service.create('$lowerEntity');
        return new ResponseEntity<>(created'$upperEntity', HttpStatus.CREATED);
    }

    @PutMapping
    public ResponseEntity<'$upperEntity'> update'$upperEntity'(@RequestBody '$upperEntity' '$lowerEntity') {
        return '$lowerEntity'Service.update('$lowerEntity') ?
                new ResponseEntity<>('$lowerEntity', HttpStatus.OK) : new ResponseEntity<>(HttpStatus.NOT_FOUND);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> delete'$upperEntity'(@PathVariable Long id) {
        '$lowerEntity'Service.delete(id);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }
	}' > $artifactId/src/main/java/$package/controllers/"$upperEntity"Controller.java
done

echo -e "\e[0;92mCreate and configure application.properties and spring rest app is ready"
