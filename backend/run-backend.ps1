$ErrorActionPreference = "Stop"

mvn -s .mvn/settings.xml package -DskipTests
java -jar target/health-recipe-0.1.0.jar
