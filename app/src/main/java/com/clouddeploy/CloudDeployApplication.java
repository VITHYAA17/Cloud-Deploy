package com.clouddeploy;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class CloudDeployApplication {

    public static void main(String[] args) {
        SpringApplication.run(CloudDeployApplication.class, args);
    }

    @GetMapping("/")
    public String hello() {
        return "Hello from CloudDeploy! CI/CD Pipeline successful.";
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}
