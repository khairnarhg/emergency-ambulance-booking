package com.rakshapoorvak.config;

import org.springframework.boot.web.embedded.tomcat.TomcatServletWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Tomcat configuration to fix macOS socket linger issue.
 * Error: java.net.SocketException: Invalid argument
 */
@Configuration
public class TomcatConfig {

    @Bean
    public WebServerFactoryCustomizer<TomcatServletWebServerFactory> tomcatCustomizer() {
        return factory -> factory.addConnectorCustomizers(connector -> {
            // Disable socket linger to fix macOS issue
            connector.setProperty("socket.soLingerOn", "false");
            connector.setProperty("socket.soLingerTime", "-1");
        });
    }
}
