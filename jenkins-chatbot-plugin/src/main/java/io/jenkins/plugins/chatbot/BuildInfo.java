package io.jenkins.plugins.chatbot;

/**
 * Information about a build that can be started by students
 */
public class BuildInfo {
    private final String buildNumber;
    private final String jobName;
    private final String description;
    
    public BuildInfo(String buildNumber, String jobName, String description) {
        this.buildNumber = buildNumber;
        this.jobName = jobName;
        this.description = description;
    }
    
    public String getBuildNumber() {
        return buildNumber;
    }
    
    public String getJobName() {
        return jobName;
    }
    
    public String getDescription() {
        return description;
    }
}
